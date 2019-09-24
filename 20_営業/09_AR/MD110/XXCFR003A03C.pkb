CREATE OR REPLACE PACKAGE BODY XXCFR003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A03C(body)
 * Description      : �������׃f�[�^�쐬
 * MD.050           : MD050_CFR_003_A03_�������׃f�[�^�쐬
 * MD.070           : MD050_CFR_003_A03_�������׃f�[�^�쐬
 * Version          : 1.180
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_target_inv_header  p �Ώې����w�b�_�f�[�^���o����            (A-2)
 *  ins_inv_detail_data    p �������׃f�[�^�쐬����                  (A-3)
 *  get_update_target_bill   p �����X�V�Ώێ擾����                  (A-10)
 *  update_bill_amount       p �������z�X�V����                      (A-11)
 *  update_trx_status      p ����f�[�^�X�e�[�^�X�X�V����            (A-9)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.00 SCS ���� �א�    ����쐬
 *  2009/02/20    1.10 SCS ���� �א�    [��QCFR_012]�e��Q���ڒǉ��Ή�
 *  2009/02/23    1.20 SCS ���� �א�    [��QCFR_013]AR������̓f�[�^������z�s��Ή�
 *  2009/07/22    1.30 SCS �A�� �^���l  [��Q0000763]�p�t�H�[�}���X���P
 *  2009/08/03    1.40 SCS �A�� �^���l  [��Q0000914]�p�t�H�[�}���X���P
 *  2009/09/29    1.50 SCS �A�� �^���l  [���ʉۑ�IE535] ���������
 *  2009/11/02    1.60 SCS �A�� �^���l  [���ʉۑ�IE603] EDI�p�ɏo�͍��ڂ�ǉ�(�[�i��`�F�[���R�[�h)
 *  2009/11/16    1.70 SCS �A�� �^���l  [���ʉۑ�IE678] �p�t�H�[�}���X�Ή�
 *  2009/12/02    1.80 SCS ���� �א�    [��Q�{�ғ�00404] �{�U�ڋq�ł̃f�[�^�擾�G���[�Ή�
 *  2010/01/04    1.90 SCS ���� �א�    [��Q�{�ғ�00826] EDI��������ԕi�敪NULL�G���[�Ή�
 *  2010/10/19    1.100 SCS ���R �L�j   [��Q�{�ғ�05091] �������̈ꕔ�`�[���z���d�����Ă��錏
 *                                                        ���̔����і��ׂƂ̏����ǉ�
 *  2011/10/11    1.110 SCS ���� �Ďj   [��Q�{�ғ�07906] EDI�̗���BMS�Ή�
 *  2012/11/06    1.120 SCSK ���� ����  [��Q�{�ғ�10090] ��ԃW���u�p�t�H�[�}���X�Ή�(JOB�̕����Ή�)
 *                                                        �g�p���Ă��Ȃ��ϐ��̍폜
 *  2013/01/17    1.130 SCSK ���� �O��  [��Q�{�ғ�09964] �������č쐬���̎d�l�������Ή�
 *  2013/06/10    1.140 SCSK ���� �O��  [��Q�{�ғ�09964�đΉ�] �������č쐬���̎d�l�������Ή�
 *  2016/03/02    1.150 SCSK ���H ���O  [��Q�{�ғ�13510] �������ɕ\������Ȃ��i�ڂ�����
 *  2019/07/26    1.160 SCSK ���Y ����  [E_�{�ғ�_15472] �y���ŗ��Ή�
 *  2019/09/06    1.170 SCSK �n� ����  [E_�{�ғ�_15472] �y���ŗ��Ή� �ǉ��Ή�
 *  2019/09/19    1.180 SCSK �s �L�i    [E_�{�ғ�_15472] �y���ŗ��Ή� �āX�Ή�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg              VARCHAR2(2000);
  gv_sep_msg              VARCHAR2(2000);
  gv_exec_user            VARCHAR2(100);
  gv_conc_name            VARCHAR2(30);
  gv_conc_status          VARCHAR2(30);
  gn_target_header_cnt    NUMBER;                    -- �Ώی���(�����w�b�_�P��)
  gn_target_line_cnt      NUMBER;                    -- �Ώی���(�������גP��)
  gn_target_aroif_cnt     NUMBER;                    -- �Ώی���(AR���OIF�o�^����)
-- Modify 2012.11.06 Ver1.120 Start
--  gn_target_del_head_cnt  NUMBER;                    -- �Ώی���(�w�b�_�f�[�^�폜����)
--  gn_target_del_line_cnt  NUMBER;                    -- �Ώی���(���׃f�[�^�폜����)
--  gn_normal_cnt           NUMBER;                    -- ���팏��
-- Modify 2012.11.06 Ver1.120 End
  gn_error_cnt            NUMBER;                    -- �G���[����
-- Modify 2012.11.06 Ver1.120 Start
--  gn_warn_cnt             NUMBER;                    -- �X�L�b�v����
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--  gn_target_up_header_cnt NUMBER;                    -- �X�V����(�����w�b�_�P��)
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
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
--
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  dml_expt              EXCEPTION;      -- �c�l�k�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  PRAGMA EXCEPTION_INIT(dml_expt, -24381);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A03C'; -- �p�b�P�[�W��
  -- �v���t�@�C���I�v�V����
-- Modify 2009.09.29 Ver1.5 Start
--  cv_prof_trx_source     CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_SOURCE';          -- �ō��z����\�[�X
--  cv_prof_trx_type       CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_TYPE';            -- �ō��z����^�C�v
--  cv_prof_trx_memo_dtl   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_MEMO_DETAIL';     -- �ō��z�����������
--  cv_prof_trx_dtl_cont   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_TAX_DIFF_TRX_DETAIL_CONTEX';   -- �ō��z������׃R���e�L�X�g�l
--  cv_prof_inv_prg_itvl   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_AUTO_INV_MST_PRG_INTERVAL';    -- �v�������`�F�b�N�ҋ@�b��
--  cv_prof_inv_prg_wait   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
--                                      := 'XXCFR1_AUTO_INV_MST_PRG_MAX_WAIT';    -- �v�������ҋ@�ő�b��
-- Modify 2009.09.29 Ver1.5 End
  cv_prof_ar_trx_source  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_AR_DEPT_INPUT_TRX_SOURCE';     -- AR������͎���\�[�X
  cv_prof_mtl_org_code   CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_MTL_ORGANIZATION_CODE';        -- �i�ڃ}�X�^�g�D�R�[�h
-- Modify 2009.08.03 Ver1.4 Start
  cv_prof_bulk_limit     CONSTANT fnd_profile_options_tl.profile_option_name%TYPE 
                                      := 'XXCFR1_BULK_LIMIT';                   -- �o���N���~�b�g�l
-- Modify 2009.08.03 Ver1.4 End
  cv_org_id              CONSTANT VARCHAR2(6)  := 'ORG_ID';                     -- �g�DID
  cv_set_of_books_id     CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';           -- ��v����ID
  cv_prof_user_name      CONSTANT VARCHAR2(8)  := 'USERNAME';                   -- ���[�U��
--
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5) := 'XXCFR';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5) := 'XXCCP';
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_ccp_90000  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; --�Ώی������b�Z�[�W
  cv_msg_ccp_90001  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; --�����������b�Z�[�W
  cv_msg_ccp_90002  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; --�G���[�������b�Z�[�W
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_ccp_90003  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003'; --�X�L�b�v�������b�Z�[�W
--  cv_msg_ccp_90004  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
--  cv_msg_ccp_90005  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
--  cv_msg_ccp_90006  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; --�G���[�I���S���[���o�b�N���b�Z�[�W
--  cv_msg_ccp_90007  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90007'; --�G���[�I���ꕔ�������b�Z�[�W
-- Modify 2009.09.29 Ver1.5 End
--
  cv_msg_cfr_00003  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --���b�N�G���[���b�Z�[�W
  cv_msg_cfr_00004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cfr_00006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --�Ɩ��������t�G���[���b�Z�[�W
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_cfr_00007  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --�f�[�^�폜�G���[���b�Z�[�W
--  cv_msg_cfr_00012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00012'; --�R���J�����g�N���G���[���b�Z�[�W
-- Modify 2009.09.29 Ver1.5 End
  cv_msg_cfr_00015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --�擾�G���[���b�Z�[�W  
  cv_msg_cfr_00016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --�f�[�^�}���G���[���b�Z�[�W
  cv_msg_cfr_00017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00017'; --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_cfr_00018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00018'; --���b�Z�[�W�^�C�g��(�w�b�_��)
  cv_msg_cfr_00019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00019'; --���b�Z�[�W�^�C�g��(���ו�)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_cfr_00043  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00043'; --�����C���{�C�X�����G���[���b�Z�[�W
--  cv_msg_cfr_00044  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00044'; --�ō��z����쐬�G���[���b�Z�[�W
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2012.11.06 Ver1.120 Start
--  cv_msg_cfr_00045  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00045'; --�G���[�I���i�����f�[�^�폜�ρj���b�Z�[�W
-- Modify 2012.11.06 Ver1.120 End
  cv_msg_cfr_00046  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00046'; --�G���[�I���i�����f�[�^���폜�j���b�Z�[�W
-- Modify 2009.09.29 Ver1.5 Start
--  cv_msg_cfr_00059  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00059'; --�g�����U�N�V�����m�胁�b�Z�[�W
--  cv_msg_cfr_00060  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00060'; --�����f�[�^�폜���b�Z�[�W
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2012.11.06 Ver1.120 Start
  cv_msg_cfr_00125  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00125'; --���̓p�����[�^�u�p���������s�敪�v�`�F�b�N�G���[���b�Z�[�W
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.01.17 Ver1.130 Start
  cv_msg_cfr_00146  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00146'; --�X�V�������b�Z�[�W
-- Modify 2013.01.17 Ver1.130 End
--
  -- ���{�ꎫ���Q�ƃR�[�h
-- Modify 2009.09.29 Ver1.5 Start
--  cv_dict_cfr_00303001  CONSTANT VARCHAR2(20) := 'CFR003A03001'; -- �ō��z�����v�z��OIF�p�f�[�^
--  cv_dict_cfr_00303002  CONSTANT VARCHAR2(20) := 'CFR003A03002'; -- �ō��z����\�[�XID
-- Modify 2009.09.29 Ver1.5 End
  cv_dict_cfr_00303003  CONSTANT VARCHAR2(20) := 'CFR003A03003'; -- AR������͎���\�[�XID
-- Modify 2009.09.29 Ver1.5 Start
--  cv_dict_cfr_00303004  CONSTANT VARCHAR2(20) := 'CFR003A03004'; -- AR���OIF�o�^�p�V�[�P���X
--  cv_dict_cfr_00303005  CONSTANT VARCHAR2(20) := 'CFR003A03005'; -- AR���OIF�e�[�u��(LINE�s)
--  cv_dict_cfr_00303006  CONSTANT VARCHAR2(20) := 'CFR003A03006'; -- AR���OIF�e�[�u��(TAX�s)
--  cv_dict_cfr_00303007  CONSTANT VARCHAR2(20) := 'CFR003A03007'; -- AR�����v�z���e�[�u��(REC�s)
--  cv_dict_cfr_00303008  CONSTANT VARCHAR2(20) := 'CFR003A03008'; -- AR�����v�z���e�[�u��(REV�s)
--  cv_dict_cfr_00303009  CONSTANT VARCHAR2(20) := 'CFR003A03009'; -- AR�����v�z���e�[�u��(TAX�s)
--  cv_dict_cfr_00303010  CONSTANT VARCHAR2(20) := 'CFR003A03010'; -- �����C���{�C�X�E�}�X�^�[�E�v���O��������
-- Modify 2009.09.29 Ver1.5 End
  cv_dict_cfr_00303011  CONSTANT VARCHAR2(20) := 'CFR003A03011'; -- ����e�[�u��
-- Modify 2009.09.29 Ver1.5 Start
--  cv_dict_cfr_00303012  CONSTANT VARCHAR2(20) := 'CFR003A03012'; -- �ō��z����^�C�vID
-- Modify 2009.09.29 Ver1.5 End
  cv_dict_cfr_00303013  CONSTANT VARCHAR2(20) := 'CFR003A03013'; -- �i�ڃ}�X�^�g�DID
  cv_dict_cfr_00303014  CONSTANT VARCHAR2(20) := 'CFR003A03014'; -- �����ΏۃR���J�����g�v��ID
-- Modify 2013.01.17 Ver1.130 Start
  cv_dict_cfr_00302009  CONSTANT VARCHAR2(20) := 'CFR003A02009'; -- �Ώێ���f�[�^����
  cv_dict_cfr_00303015  CONSTANT VARCHAR2(20) := 'CFR003A03015'; -- �����w�b�_�f�[�^�쐬�p�����[�^������ڋq
-- Modify 2013.01.17 Ver1.130 End
--
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_prof_name  CONSTANT VARCHAR2(30)  := 'PROF_NAME';       -- �v���t�@�C���I�v�V������
  cv_tkn_table      CONSTANT VARCHAR2(30)  := 'TABLE';           -- �e�[�u����
-- Modify 2009.09.29 Ver1.5 Start
--  cv_tkn_prg_name   CONSTANT VARCHAR2(30)  := 'PROGRAM_NAME';    -- �v���O������
--  cv_tkn_sqlerrm    CONSTANT VARCHAR2(30)  := 'SQLERRM';         -- SQL�G���[���b�Z�[�W
--  cv_tkn_req_id     CONSTANT VARCHAR2(30)  := 'REQUEST_ID';      -- �v��ID
--  cv_tkn_cust_code  CONSTANT VARCHAR2(30)  := 'CUST_CODE';       -- �ڋq�R�[�h
--  cv_tkn_cust_name  CONSTANT VARCHAR2(30)  := 'CUST_NAME';       -- �ڋq��
-- Modify 2009.09.29 Ver1.5 End
  cv_tkn_data       CONSTANT VARCHAR2(30)  := 'DATA';            -- �f�[�^
  cv_tkn_count      CONSTANT VARCHAR2(30)  := 'COUNT';           -- ����
--
  -- �g�pDB��
  cv_table_xiit       CONSTANT VARCHAR2(100) := 'XXCFR_INV_INFO_TRANSFER';     -- ���������n�e�[�u��
  cv_table_xtcl       CONSTANT VARCHAR2(100) := 'XXCFR_INV_TARGET_CUST_LIST';  -- �������Ώیڋq���[�N�e�[�u��
  cv_table_xxih       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_HEADERS';       -- �����w�b�_���e�[�u��
  cv_table_xxil       CONSTANT VARCHAR2(100) := 'XXCFR_INVOICE_LINES';         -- �������׏��e�[�u��
  cv_table_xxgt       CONSTANT VARCHAR2(100) := 'XXCFR_TAX_GAP_TRX_LIST';      -- �ō��z����쐬�e�[�u��
--
  -- �Q�ƃ^�C�v
-- Modify 2009.09.29 Ver1.5 Start
--  cv_lookup_aroif_dist     CONSTANT VARCHAR2(100) := 'XXCFR1_TAX_DIFF_AR_IF_DIST';  -- ���OIF�z���p�f�[�^
-- Modify 2009.09.29 Ver1.5 End
  cv_lookup_itm_yokigun    CONSTANT VARCHAR2(100) := 'XXCMM_ITM_YOKIGUN';           -- �e��Q
  cv_lookup_itm_yokikubun  CONSTANT VARCHAR2(100) := 'XXCMM_YOKI_KUBUN';            -- �e��敪
  cv_lookup_slip_class     CONSTANT VARCHAR2(100) := 'XXCOS1_DELIVERY_SLIP_CLASS';  -- �[�i�`�[�敪
  cv_lookup_sale_class     CONSTANT VARCHAR2(100) := 'XXCOS1_SALE_CLASS';           -- ����敪
  cv_lookup_vd_class_type  CONSTANT VARCHAR2(100) := 'XXCFR1_VD_TARGET_CLASS_TYPE'; -- �ėp����VD�Ώۏ�����
--
  -- �t�@�C���o��
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_account_class_rec  CONSTANT VARCHAR2(3)  := 'REC';       -- ����敪(���|/������)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_account_class_rev  CONSTANT VARCHAR2(3)  := 'REV';       -- ����敪(���v)
--  cv_account_class_tax  CONSTANT VARCHAR2(3)  := 'TAX';       -- ����敪(�ŋ�)
-- Modify 2009.09.29 Ver1.5 End
  cv_inv_hold_status_o  CONSTANT VARCHAR2(4)  := 'OPEN';      -- �������ۗ��X�e�[�^�X(�I�[�v��)
  cv_inv_hold_status_r  CONSTANT VARCHAR2(7)  := 'REPRINT';   -- �������ۗ��X�e�[�^�X(�Đ���)
  cv_inv_hold_status_p  CONSTANT VARCHAR2(7)  := 'PRINTED';   -- �������ۗ��X�e�[�^�X(�����)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_inv_hold_status_w  CONSTANT VARCHAR2(7)  := 'WAITING';   -- �������ۗ��X�e�[�^�X(�ۗ�)
-- Modify 2009.09.29 Ver1.5 End
  cv_line_type_tax      CONSTANT VARCHAR2(3)  := 'TAX';       -- ������׃^�C�v(�ŋ�)
  cv_line_type_line     CONSTANT VARCHAR2(4)  := 'LINE';      -- ������׃^�C�v(����)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_get_acct_name_f    CONSTANT VARCHAR2(1)  := '0';         -- �ڋq���̎擾�֐��p�����[�^(�S�p)
--  cv_get_acct_name_k    CONSTANT VARCHAR2(1)  := '1';         -- �ڋq���̎擾�֐��p�����[�^(�J�i)
-- Modify 2009.09.29 Ver1.5 End
  cv_inv_type_no        CONSTANT VARCHAR2(2)  := '00';        -- �����敪(�ʏ�)
  cv_inv_type_re        CONSTANT VARCHAR2(2)  := '01';        -- �����敪(�Đ���)
  cv_tax_div_outtax     CONSTANT VARCHAR2(1)  := '1';         -- ����ŋ敪(�O��)
  cv_tax_div_inslip     CONSTANT VARCHAR2(1)  := '2';         -- ����ŋ敪(����(�`�[))
  cv_tax_div_inunit     CONSTANT VARCHAR2(1)  := '3';         -- ����ŋ敪(����(�P��))
  cv_tax_div_notax      CONSTANT VARCHAR2(1)  := '4';         -- ����ŋ敪(��ې�)
-- Modify 2009.09.29 Ver1.5 Start
--  cv_currency_code      CONSTANT VARCHAR2(3)  := 'JPY';       -- �ʉ݃R�[�h
--  cv_conversion_type    CONSTANT VARCHAR2(4)  := 'User';      -- ���Z�^�C�v
--  cn_conversion_rate    CONSTANT NUMBER       := 1;           -- ���Z���[�g
--  cv_amt_incl_tax_flg_n CONSTANT VARCHAR2(1)  := 'N';         -- �ō����z�t���O(N)
--  cv_amt_incl_tax_flg_y CONSTANT VARCHAR2(1)  := 'Y';         -- �ō����z�t���O(Y)
--  cv_enabled_flag_y     CONSTANT VARCHAR2(1)  := 'Y';         -- �L���t���O(Y)
--
--  -- �����C���{�C�X�N���p
--  cv_auto_inv_appl_name CONSTANT VARCHAR2(2)   := 'AR';       -- �����C���{�C�X�A�v���P�[�V������
--  cv_auto_inv_prg_name  CONSTANT VARCHAR2(6)   := 'RAXMTR';   -- �����C���{�C�X�v���O������
--  cv_conc_phase_cmplt   CONSTANT VARCHAR2(8)   := 'COMPLETE'; -- �R���J�����g���(����)
--  cv_conc_status_norml  CONSTANT VARCHAR2(6)   := 'NORMAL';   -- �R���J�����g�I���X�e�[�^�X(����)
  -- �󒍃\�[�X(�}�̋敪)
  cv_medium_class_edi   CONSTANT VARCHAR2(2)  := '00';          -- �}�̋敪:EDI
  cv_medium_class_mnl   CONSTANT VARCHAR2(2)  := '01';          -- �}�̋敪:�����
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2010.01.04 Ver1.9 Start
  cv_sold_return_type_ar  CONSTANT VARCHAR2(1)  := '1';         -- ����ԕi�敪(AR������͗p)
-- Modify 2010.01.04 Ver1.9 End
-- Modify 2012.11.06 Ver1.120 Start
  cv_judge_type_batch   CONSTANT VARCHAR2(1)  := '2';           -- ��Ԏ蓮���f�敪(���)
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
  cv_inv_creation_flag  CONSTANT VARCHAR2(1)  := 'Y';           -- �����쐬�Ώۃt���O(Y)
-- Modify 2013.06.10 Ver1.140 End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
-- Modify 2012.11.06 Ver1.120 Start
--    TYPE get_invoice_id_ttype    IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE 
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cust_code_ttype     IS TABLE OF xxcfr_invoice_headers.bill_cust_code%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cutoff_date_ttype   IS TABLE OF xxcfr_invoice_headers.cutoff_date%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cust_acct_id_ttype  IS TABLE OF xxcfr_invoice_headers.bill_cust_account_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_cust_site_id_ttype  IS TABLE OF xxcfr_invoice_headers.bill_cust_acct_site_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_gap_amt_ttype   IS TABLE OF xxcfr_invoice_headers.tax_gap_amount%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_term_name_ttype     IS TABLE OF xxcfr_invoice_headers.term_name%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_term_id_ttype       IS TABLE OF xxcfr_invoice_headers.term_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_send_addr1_ttype    IS TABLE OF xxcfr_invoice_headers.send_address1%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_send_addr2_ttype    IS TABLE OF xxcfr_invoice_headers.send_address2%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_send_addr3_ttype    IS TABLE OF xxcfr_invoice_headers.send_address3%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_rec_loc_code_ttype  IS TABLE OF xxcfr_invoice_headers.receipt_location_code%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_type_ttype      IS TABLE OF xxcfr_invoice_headers.tax_type%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_bil_loc_code_ttype  IS TABLE OF xxcfr_invoice_headers.bill_location_code%TYPE
--                                             INDEX BY PLS_INTEGER;
----
--    gt_invoice_id_tab        get_invoice_id_ttype;
--    gt_cust_code_tab         get_cust_code_ttype;
--    gt_cutoff_date_tab       get_cutoff_date_ttype;
--    gt_cust_acct_id_tab      get_cust_acct_id_ttype;
--    gt_cust_site_id_tab      get_cust_site_id_ttype;
--    gt_tax_gap_amt_tab       get_tax_gap_amt_ttype;
--    gt_term_name_tab         get_term_name_ttype;
--    gt_term_id_tab           get_term_id_ttype;
--    gt_send_addr1_tab        get_send_addr1_ttype;
--    gt_send_addr2_tab        get_send_addr2_ttype;
--    gt_send_addr3_tab        get_send_addr3_ttype;
--    gt_rec_loc_code_tab      get_rec_loc_code_ttype;
--    gt_tax_type_tab          get_tax_type_ttype;
--    gt_bil_loc_code_tab      get_bil_loc_code_ttype;
-- Modify 2012.11.06 Ver1.120 End
--
-- Modify 2013.01.17 Ver1.130 Start
    TYPE get_inv_id_ttype          IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_amt_no_tax_ttype      IS TABLE OF xxcfr_invoice_headers.inv_amount_no_tax%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_tax_amt_sum_ttype     IS TABLE OF xxcfr_invoice_headers.tax_amount_sum%TYPE
                                                  INDEX BY PLS_INTEGER;
    TYPE get_amd_inc_tax_ttype     IS TABLE OF xxcfr_invoice_headers.inv_amount_includ_tax%TYPE
                                                  INDEX BY PLS_INTEGER;
--
    gt_get_inv_id_tab            get_inv_id_ttype;
    gt_get_amt_no_tax_tab        get_amt_no_tax_ttype;
    gt_get_tax_amt_sum_tab       get_tax_amt_sum_ttype;
    gt_get_amd_inc_tax_tab       get_amd_inc_tax_ttype;
-- Modify 2013.01.17 Ver1.130 End
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
-- Modify 2009.09.29 Ver1.5 Start
--  gt_taxd_trx_source     fnd_profile_option_values.profile_option_value%TYPE;  -- �ō��z����\�[�X
--  gt_taxd_trx_type       fnd_profile_option_values.profile_option_value%TYPE;  -- �ō��z����^�C�v
--  gt_taxd_trx_memo_dtl   fnd_profile_option_values.profile_option_value%TYPE;  -- �ō��z�����������
--  gt_taxd_trx_dtl_cont   fnd_profile_option_values.profile_option_value%TYPE;  -- �ō��z������׃R���e�L�X�g�l
--  gt_taxd_inv_prg_itvl   fnd_profile_option_values.profile_option_value%TYPE;  -- �v�������`�F�b�N�ҋ@�b��
--  gt_taxd_inv_prg_wait   fnd_profile_option_values.profile_option_value%TYPE;  -- �v�������ҋ@�ő�b��
-- Modify 2009.09.29 Ver1.5 End
  gt_taxd_ar_trx_source  fnd_profile_option_values.profile_option_value%TYPE;  -- AR������͎���\�[�X
  gt_mtl_org_code        fnd_profile_option_values.profile_option_value%TYPE;  -- �i�ڃ}�X�^�g�D�R�[�h
-- Modify 2009.09.29 Ver1.5 Start
--  gt_rec_aff_segment1    gl_code_combinations.segment1%TYPE;                   -- AFF���
--  gt_rec_aff_segment2    gl_code_combinations.segment2%TYPE;                   -- AFF����
--  gt_rec_aff_segment5    gl_code_combinations.segment5%TYPE;                   -- AFF�ڋq�R�[�h
--  gt_rec_aff_segment6    gl_code_combinations.segment6%TYPE;                   -- AFF��ƃR�[�h
--  gt_rec_aff_segment7    gl_code_combinations.segment7%TYPE;                   -- AFF�\���P
--  gt_rec_aff_segment8    gl_code_combinations.segment8%TYPE;                   -- AFF�\���Q
-- Modify 2009.09.29 Ver1.5 End
  gt_user_name           fnd_profile_option_values.profile_option_value%TYPE;  -- ���[�U��
-- Modify 2009.09.29 Ver1.5 Start
--  gt_tax_gap_trx_source_id  ra_batch_sources_all.batch_source_id%TYPE;         -- �ō��z����\�[�XID
-- Modify 2009.09.29 Ver1.5 End
  gt_arinput_trx_source_id  ra_batch_sources_all.batch_source_id%TYPE;         -- AR������͎���\�[�XID
-- Modify 2009.09.29 Ver1.5 Start
--  gt_tax_gap_trx_type_id    ra_cust_trx_types_all.cust_trx_type_id%TYPE;       -- �ō��z����^�C�vID
-- Modify 2009.09.29 Ver1.5 End
  gt_target_request_id      xxcfr_inv_info_transfer.target_request_id%TYPE;    -- �����ΏۃR���J�����g�v��ID
  gt_mtl_organization_id mtl_parameters.organization_id%TYPE;                  -- �i�ڃ}�X�^�g�DID
-- Modify 2013.01.17 Ver1.130 Start
  gt_bill_acct_code         xxcfr_inv_info_transfer.bill_acct_code%TYPE;       -- ������ڋq�R�[�h
-- Modify 2013.01.17 Ver1.130 End
--
-- Modify 2012.11.06 Ver1.120 Start
--  gd_target_date         DATE;                                                 -- ����(���t�^)
-- Modify 2012.11.06 Ver1.120 End
  gn_org_id              NUMBER;                                               -- �g�DID
  gn_set_book_id         NUMBER;                                               -- ��v����ID
  gd_process_date        DATE;                                                 -- �Ɩ��������t
-- Modify 2012.11.06 Ver1.120 Start
--  gd_work_day_ago1       DATE;                                                 -- 1�c�Ɠ��O��
--  gd_work_day_ago2       DATE;                                                 -- 2�c�Ɠ��O��
--  gv_warning_flag        VARCHAR2(1);                                          -- �x���t���O
--  gv_auto_inv_err_flag   VARCHAR2(1);                                          -- �����C���{�C�X�G���[�t���O
-- Modify 2012.11.06 Ver1.120 End
--
-- Modify 2009.08.03 Ver1.4 Start
  gn_bulk_limit          PLS_INTEGER;     -- �o���N�̃��~�b�g�l
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2012.11.06 Ver1.120 Start
  gn_parallel_type       NUMBER      DEFAULT NULL; -- �p���������s�敪
  gv_batch_on_judge_type VARCHAR2(1) DEFAULT NULL; -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- Modify 2012.11.06 Ver1.120 Start
    iv_parallel_type        IN  VARCHAR2,     -- �p���������s�敪
    iv_batch_on_judge_type  IN  VARCHAR2,     -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_prof_name        fnd_profile_options_tl.user_profile_option_name%TYPE;
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
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
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out        -- ���b�Z�[�W�o��
-- Modify 2012.11.06 Ver1.120 Start
      ,iv_conc_param1  => iv_parallel_type        -- �p���������s�敪
      ,iv_conc_param2  => iv_batch_on_judge_type  -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
      ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log        -- ���O�o��
-- Modify 2012.11.06 Ver1.120 Start
      ,iv_conc_param1  => iv_parallel_type        -- �p���������s�敪
      ,iv_conc_param2  => iv_batch_on_judge_type  -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
      ,ov_errbuf       => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- Modify 2012.11.06 Ver1.120 Start
    -- ���̓p�����[�^�u��Ԏ蓮���f�敪�v�̐ݒ�
    gv_batch_on_judge_type := iv_batch_on_judge_type;
    --
    --==============================================================
    -- ���̓p�����[�^�`�F�b�N
    --==============================================================
    -- ���̓p�����[�^�u��Ԏ蓮���f�敪�v��'2'(���)�̏ꍇ
    IF ( gv_batch_on_judge_type = cv_judge_type_batch ) THEN
      -- ���̓p�����[�^�u�p���������s�敪�v�K�{�`�F�b�N
      IF ( iv_parallel_type IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- �A�v���P�[�V�����Z�k��
                                             ,iv_name         => cv_msg_cfr_00125);  -- ���b�Z�[�W
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_api_expt;
      END IF;
      -- ���̓p�����[�^�u�p���������s�敪�v���l�`�F�b�N
      BEGIN
        gn_parallel_type := TO_NUMBER( iv_parallel_type );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- �A�v���P�[�V�����Z�k��
                                               ,iv_name         => cv_msg_cfr_00125);  -- ���b�Z�[�W
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
-- Modify 2012.11.06 Ver1.120 End
    --==============================================================
    --�v���t�@�C���擾����
    --==============================================================
-- Modify 2009.09.29 Ver1.5 Start
--    --�ō��z����\�[�X
--    gt_taxd_trx_source := fnd_profile.value(cv_prof_trx_source);
--    IF (gt_taxd_trx_source IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_source);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --�ō��z����^�C�v
--    gt_taxd_trx_type := fnd_profile.value(cv_prof_trx_type);
--    IF (gt_taxd_trx_type IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_type);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --�ō��z�����������
--    gt_taxd_trx_memo_dtl := fnd_profile.value(cv_prof_trx_memo_dtl);
--    IF (gt_taxd_trx_memo_dtl IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_memo_dtl);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --�ō��z������׃R���e�L�X�g�l
--    gt_taxd_trx_dtl_cont := fnd_profile.value(cv_prof_trx_dtl_cont);
--    IF (gt_taxd_trx_dtl_cont IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_trx_dtl_cont);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --�v�������`�F�b�N�ҋ@�b��
--    gt_taxd_inv_prg_itvl := fnd_profile.value(cv_prof_inv_prg_itvl);
--    IF (gt_taxd_inv_prg_itvl IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_inv_prg_itvl);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--    --�v�������ҋ@�ő�b��
--    gt_taxd_inv_prg_wait := fnd_profile.value(cv_prof_inv_prg_wait);
--    IF (gt_taxd_inv_prg_wait IS NULL) THEN
--      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_inv_prg_wait);
--      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
--                                                    ,iv_name         => cv_msg_cfr_00004
--                                                    ,iv_token_name1  => cv_tkn_prof_name
--                                                    ,iv_token_value1 => lt_prof_name)
--                                                    ,1
--                                                    ,5000);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- Modify 2009.09.29 Ver1.5 End
--
    --AR������͎���\�[�X
    gt_taxd_ar_trx_source := fnd_profile.value(cv_prof_ar_trx_source);
    IF (gt_taxd_ar_trx_source IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_ar_trx_source);
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_cfr_00004
                                                    ,iv_token_name1  => cv_tkn_prof_name
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�i�ڃ}�X�^�g�D�R�[�h
    gt_mtl_org_code := fnd_profile.value(cv_prof_mtl_org_code);
    IF (gt_mtl_org_code IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_mtl_org_code);
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr
                                                    ,iv_name         => cv_msg_cfr_00004
                                                    ,iv_token_name1  => cv_tkn_prof_name
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�g�DID
    gn_org_id := TO_NUMBER(fnd_profile.value(cv_org_id));
    IF (gn_org_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_org_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --��v����ID
    gn_set_book_id := TO_NUMBER(fnd_profile.value(cv_set_of_books_id));
    IF (gn_set_book_id IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_set_of_books_id);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --���[�U��
    gt_user_name := fnd_profile.value(cv_prof_user_name);
    IF (gt_user_name IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_user_name);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.08.03 Ver1.4 Start
    -- �o���N�̃��~�b�g�l��ݒ�
    gn_bulk_limit := fnd_profile.value(cv_prof_bulk_limit);
    IF (gn_bulk_limit IS NULL) THEN
      lt_prof_name := xxcfr_common_pkg.get_user_profile_name(cv_prof_bulk_limit);
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00004  
                                                    ,iv_token_name1  => cv_tkn_prof_name  
                                                    ,iv_token_value1 => lt_prof_name)
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Modify 2009.08.03 Ver1.4 End
    --==============================================================
    --�Ɩ��������t�擾����
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date());
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr    
                                                    ,iv_name         => cv_msg_cfr_00006  )
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009.09.29 Ver1.5 Start
--    --==============================================================
--    --�ō��z�����v�z���pOIF���R�[�h�p�f�[�^���o����
--    --==============================================================
--    BEGIN
--      SELECT fnlv.attribute1     attribute1,
--             fnlv.attribute2     attribute2,
--             fnlv.attribute5     attribute5,
--             fnlv.attribute6     attribute6,
--             fnlv.attribute7     attribute7,
--             fnlv.attribute8     attribute8
--      INTO   gt_rec_aff_segment1,
--             gt_rec_aff_segment2,
--             gt_rec_aff_segment5,
--             gt_rec_aff_segment6,
--             gt_rec_aff_segment7,
--             gt_rec_aff_segment8
--      FROM   fnd_lookup_values         fnlv        -- �N�C�b�N�R�[�h
--      WHERE  fnlv.lookup_code  = cv_account_class_rec          --����敪(���|/������)
--      AND    fnlv.lookup_type  = cv_lookup_aroif_dist
--      AND    fnlv.language     = USERENV( 'LANG' )
--      AND    fnlv.enabled_flag = 'Y'
--      AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active, gd_process_date ) )
--                                 AND  TRUNC( NVL( fnlv.end_date_active,   gd_process_date ) )
--      AND    ROWNUM = 1
--      ;
----
--    EXCEPTION
--      -- *** OTHERS��O�n���h�� ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                               iv_keyword            => cv_dict_cfr_00303001);    -- �z��OIF�p�f�[�^
--        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cfr,
--                               iv_name         => cv_msg_cfr_00015,  
--                               iv_token_name1  => cv_tkn_data,  
--                               iv_token_value1 => lt_look_dict_word),
--                             1,
--                             5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
----
--    --==============================================================
--    --����\�[�XID�̒��o����
--    --==============================================================
--    --�ō��z����\�[�XID
--    BEGIN
--      SELECT rbsa.batch_source_id     batch_source_id
--      INTO   gt_tax_gap_trx_source_id
--      FROM   ra_batch_sources_all  rbsa
--      WHERE  rbsa.name = gt_taxd_trx_source
--      AND    rbsa.org_id = gn_org_id
--      ;
----
--    EXCEPTION
--        -- *** OTHERS��O�n���h�� ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303002);    -- �ō��z����\�[�XID
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
-- Modify 2009.09.29 Ver1.5 End
--
    --AR������͎���\�[�XID
    BEGIN
      SELECT rbsa.batch_source_id      batch_source_id
      INTO   gt_arinput_trx_source_id
      FROM   ra_batch_sources_all  rbsa
      WHERE  rbsa.name = gt_taxd_ar_trx_source
      AND    rbsa.org_id = gn_org_id
      ;
--
    EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303003);    -- AR������͎���\�[�XID
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
-- Modify 2009.09.29 Ver1.5 Start
--    --==============================================================
--    --�ō��z�v����^�C�vID���o����
--    --==============================================================
--    -- ����^�C�vID
--    BEGIN
--      SELECT rctt.cust_trx_type_id    batch_source_id
--      INTO   gt_tax_gap_trx_type_id
--      FROM   ra_cust_trx_types_all    rctt
--      WHERE  rctt.name = gt_taxd_trx_type                 -- ����^�C�v��
--      AND    gd_process_date BETWEEN  TRUNC( NVL( rctt.start_date, gd_process_date ) )
--                                 AND  TRUNC( NVL( rctt.end_date,   gd_process_date ) )
--      AND    rctt.set_of_books_id = gn_set_book_id        -- ��v����ID
--      AND    rctt.org_id = gn_org_id                      -- �g�DID
--      ;
----
--    EXCEPTION
--        -- *** OTHERS��O�n���h�� ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303012);    -- �ō��z����^�C�vID
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
-- Modify 2009.09.29 Ver1.5 End
--
    --==============================================================
    --�i�ڃ}�X�^�g�DID���o����
    --==============================================================
    --�i�ڃ}�X�^�g�DID
    BEGIN
      SELECT mtlp.organization_id
      INTO   gt_mtl_organization_id
      FROM   mtl_parameters mtlp
      WHERE  mtlp.organization_code = gt_mtl_org_code
      ;
--
    EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303013);    -- �i�ڃ}�X�^�g�DID
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;

--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �f�[�^�擾��O�n���h�� ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_target_inv_header
   * Description      : �Ώې����w�b�_�f�[�^���o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_inv_header(
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_inv_header'; -- �v���O������
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
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �����w�b�_�f�[�^�J�[�\��
-- Modify 2012.11.06 Ver1.120 Start
--    CURSOR get_inv_header_cur(
--      iv_request_id    VARCHAR2
--    )
--    IS
---- Modify 2009.08.03 Ver1.4 Start
----      SELECT xxih.invoice_id              invoice_id,             -- �ꊇ������ID
--      SELECT /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
--             xxih.invoice_id              invoice_id,             -- �ꊇ������ID
------ Modify 2009.08.03 Ver1.4 End
--             xxih.bill_cust_code          bill_cust_code,         -- ������ڋq�R�[�h
--             xxih.cutoff_date             cutoff_date,            -- ����
--             xxih.bill_cust_account_id    bill_cust_account_id,   -- ������ڋqID
--             xxih.bill_cust_acct_site_id  bill_cust_acct_site_id, -- ������ڋq���ݒnID
--             xxih.tax_gap_amount          tax_gap_amount,         -- �ō��z
--             xxih.term_name               term_name,              -- �x������
--             xxih.term_id                 term_id,                -- �x������ID
--             xxih.send_address1           send_address1,          -- ���t��Z��1
--             xxih.send_address2           send_address2,          -- ���t��Z��2
--             xxih.send_address3           send_address3,          -- ���t��Z��3
--             xxih.receipt_location_code   receipt_location_code,  -- �������_�R�[�h
--             xxih.tax_type                tax_type,               -- ����ŋ敪
--             xxih.bill_location_code      bill_location_code      -- �������_�R�[�h
--      FROM   xxcfr_invoice_headers xxih                   -- �����w�b�_���e�[�u��
--      WHERE  xxih.request_id = iv_request_id              -- �R���J�����g�v��ID
--      AND    xxih.org_id = gn_org_id                      -- �g�DID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- ��v����ID
--      FOR UPDATE NOWAIT
    CURSOR get_inv_header_cur
    IS
      SELECT /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
             COUNT(1)              xxih_count             -- ����
      FROM   xxcfr_invoice_headers xxih                   -- �����w�b�_���e�[�u��
      WHERE  xxih.request_id       = gt_target_request_id -- �R���J�����g�v��ID
      AND    xxih.org_id           = gn_org_id            -- �g�DID
      AND    xxih.set_of_books_id  = gn_set_book_id       -- ��v����ID
      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'2'(���)
      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- �p���������s�敪����v
      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'0'(�蓮)
      AND     ( xxih.parallel_type     IS NULL ) ) )            -- �p���������s�敪��NULL
-- Modify 2012.11.06 Ver1.120 End
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
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
    --���������n�e�[�u���f�[�^���o����
    --==============================================================
    -- �����ΏۃR���J�����g�v��ID���o
--
    BEGIN
      SELECT xiit.target_request_id  target_request_id
      INTO   gt_target_request_id
      FROM   xxcfr_inv_info_transfer xiit
      WHERE  xiit.set_of_books_id = gn_set_book_id
      AND    xiit.org_id = gn_org_id
      ;
--
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00303014);    -- �����ΏۃR���J�����g�v��ID
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
-- Modify 2013.01.17 Ver1.130 Start
    -- �����w�b�_�f�[�^�쐬�p�����[�^������ڋq���o�i�蓮���s���p�j
    IF (gv_batch_on_judge_type != cv_judge_type_batch) THEN
      BEGIN
        SELECT xiit.bill_acct_code     bill_acct_code
        INTO   gt_bill_acct_code
        FROM   xxcfr_inv_info_transfer xiit
        WHERE  xiit.set_of_books_id = gn_set_book_id
        AND    xiit.org_id = gn_org_id
        ;
--
      EXCEPTION
      -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303015);  -- �����w�b�_�f�[�^�쐬������ڋq
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cfr,
                                   iv_name         => cv_msg_cfr_00015,  
                                   iv_token_name1  => cv_tkn_data,  
                                   iv_token_value1 => lt_look_dict_word),
                                 1,
                                 5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- �����w�b�_�f�[�^�쐬�p�����[�^������ڋq�̕K�{�`�F�b�N
      IF ( gt_bill_acct_code IS NULL ) THEN
        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
                               iv_keyword            => cv_dict_cfr_00303015);  -- �����w�b�_�f�[�^�쐬������ڋq
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr,
                                 iv_name         => cv_msg_cfr_00015,  
                                 iv_token_name1  => cv_tkn_data,  
                                 iv_token_value1 => lt_look_dict_word),
                               1,
                               5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    END IF;
-- Modify 2013.01.17 Ver1.130 End
    --�����w�b�_���f�[�^���o����
-- Modify 2012.11.06 Ver1.120 Start
--    -- �J�[�\���I�[�v��
--    OPEN get_inv_header_cur(
--           gt_target_request_id
--         );
--
--    -- �f�[�^�̈ꊇ�擾
--    FETCH get_inv_header_cur 
--    BULK COLLECT INTO gt_invoice_id_tab,    -- �ꊇ������ID
--                      gt_cust_code_tab,     -- ������ڋq�R�[�h
--                      gt_cutoff_date_tab,   -- ����
--                      gt_cust_acct_id_tab,  -- ������ڋqID
--                      gt_cust_site_id_tab,  -- ������ڋq���ݒnID
--                      gt_tax_gap_amt_tab,   -- �ō��z
--                      gt_term_name_tab,     -- �x������
--                      gt_term_id_tab,       -- �x������ID
--                      gt_send_addr1_tab,    -- ���t��Z��1
--                      gt_send_addr2_tab,    -- ���t��Z��2
--                      gt_send_addr3_tab,    -- ���t��Z��3
--                      gt_rec_loc_code_tab,  -- �������_�R�[�h
--                      gt_tax_type_tab,      -- ����ŋ敪
--                      gt_bil_loc_code_tab   -- �������_�R�[�h
--    ;
----
--    -- ���������̃Z�b�g
--    gn_target_header_cnt := gt_invoice_id_tab.COUNT;
    -- �J�[�\���I�[�v��
    OPEN get_inv_header_cur;
    --
    -- ���������̃Z�b�g
    FETCH get_inv_header_cur INTO gn_target_header_cnt;
-- Modify 2012.11.06 Ver1.120 End
--
    -- �J�[�\���N���[�Y
    CLOSE get_inv_header_cur;
--
  EXCEPTION
    -- *** �e�[�u�����b�N�G���[�n���h�� ***
    WHEN lock_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_inv_header_cur%ISOPEN ) THEN
        CLOSE get_inv_header_cur;
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                             ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                       -- �����w�b�_���e�[�u��
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_inv_header_cur%ISOPEN ) THEN
        CLOSE get_inv_header_cur;
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_inv_header_cur%ISOPEN ) THEN
        CLOSE get_inv_header_cur;
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_target_inv_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_inv_detail_data
   * Description      : �������׃f�[�^�쐬����(A-3)
   ***********************************************************************************/
  PROCEDURE ins_inv_detail_data(
-- Modify 2009.07.22 Ver1.3 Start
--    in_invoice_id           IN  NUMBER,       -- �ꊇ������ID
--    iv_cust_acct_id         IN  VARCHAR2,     -- ������ڋqID
--    id_cutoff_date          IN  DATE,         -- ����
--    iv_tax_type             IN  VARCHAR2,     -- ����ŋ敪
-- Modify 2009.07.22 Ver1.3 End
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_detail_data'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
--
    -- *** ���[�J���E�J�[�\�� ***
-- Modify 2009.08.03 Ver1.4 Start
    CURSOR main_data_cur 
    IS
    SELECT inlv.invoice_id                   invoice_id,                    -- �ꊇ������ID
           ROWNUM                            invoice_detail_num,            -- �ꊇ����������No
           inlv.note_line_id                 note_line_id,                  -- �`�[����No
           inlv.ship_cust_code               ship_cust_code,                -- �[�i��ڋq�R�[�h
-- Modify 2009.09.29 Ver1.5 Start
--           ship.party_name                   ship_cust_name,                -- �[�i��ڋq��
--           ship.organization_name_phonetic   ship_cust_kana_name,           -- �[�i��ڋq�J�i��
           inlv.ship_cust_name               ship_cust_name,                -- �[�i��ڋq��
           inlv.ship_cust_kana_name          ship_cust_kana_name,           -- �[�i��ڋq�J�i��
-- Modify 2009.09.29 Ver1.5 End
           inlv.sold_location_code           sold_location_code,            -- ���㋒�_�R�[�h
-- Modify 2009.09.29 Ver1.5 Start
--           sold.party_name                   sold_location_name,            -- ���㋒�_��
           inlv.sold_location_name           sold_location_name,            -- ���㋒�_��
-- Modify 2009.09.29 Ver1.5 End
           inlv.ship_shop_code               ship_shop_code,                -- �[�i��X�܃R�[�h
           inlv.ship_shop_name               ship_shop_name,                -- �[�i��X��
           inlv.vd_num                       vd_num,                        -- �����̔��@�ԍ�
           inlv.vd_cust_type                 vd_cust_type,                  -- VD�ڋq�敪
           inlv.inv_type                     inv_type,                      -- �����敪
           inlv.chain_shop_code              chain_shop_code,               -- �`�F�[���X�R�[�h
           inlv.delivery_date                delivery_date,                 -- �[�i��
           inlv.slip_num                     slip_num,                      -- �`�[�ԍ�
           inlv.order_num                    order_num,                     -- �I�[�_�[NO
           inlv.column_num                   column_num,                    -- �R����No
           inlv.slip_type                    slip_type,                     -- �`�[�敪
           inlv.classify_type                classify_type,                 -- ���ދ敪
           inlv.customer_dept_code           customer_dept_code,            -- ���q�l����R�[�h
           inlv.customer_division_code       customer_division_code,        -- ���q�l�ۃR�[�h
           inlv.sold_return_type             sold_return_type,              -- ����ԕi�敪
           inlv.nichiriu_by_way_type         nichiriu_by_way_type,          -- �j�`���E�o�R�敪
           inlv.sale_type                    sale_type,                     -- �����敪
           inlv.direct_num                   direct_num,                    -- ��No
           inlv.po_date                      po_date,                       -- ������
           inlv.acceptance_date              acceptance_date,               -- ������
           inlv.item_code                    item_code,                     -- ���iCD
           inlv.item_name                    item_name,                     -- ���i��
           inlv.item_kana_name               item_kana_name,                -- ���i�J�i��
           inlv.policy_group                 policy_group,                  -- ����Q�R�[�h
           inlv.jan_code                     jan_code,                      -- JAN�R�[�h
           inlv.vessel_type                  vessel_type,                   -- �e��敪
           inlv.vessel_type_name             vessel_type_name,              -- �e��敪��
           inlv.vessel_group                 vessel_group,                  -- �e��Q
           inlv.vessel_group_name            vessel_group_name,             -- �e��Q��
           inlv.quantity                     quantity,                      -- ����
           inlv.unit_price                   unit_price,                    -- �P��
           inlv.dlv_qty                      dlv_qty,                       -- �[�i����
           inlv.dlv_unit_price               dlv_unit_price,                -- �[�i�P��
           inlv.dlv_uom_code                 dlv_uom_code,                  -- �[�i�P��
           inlv.standard_uom_code            standard_uom_code,             -- ��P��
           inlv.standard_unit_price_excluded standard_unit_price_excluded,  -- �Ŕ���P��
           inlv.business_cost                business_cost,                 -- �c�ƌ���
           inlv.tax_amount                   tax_amount,                    -- ����ŋ��z
           inlv.tax_rate                     tax_rate,                      -- ����ŗ�
           inlv.ship_amount                  ship_amount,                   -- �[�i���z
           inlv.sold_amount                  sold_amount,                   -- ������z
           inlv.red_black_slip_type          red_black_slip_type,           -- �ԓ`���`�敪
           inlv.trx_id                       trx_id,                        -- ���ID
           inlv.trx_number                   trx_number,                    -- ����ԍ�
           inlv.cust_trx_type_id             cust_trx_type_id,              -- ����^�C�vID
           inlv.batch_source_id              batch_source_id,               -- ����\�[�XID
           inlv.created_by                   created_by,                    -- �쐬��
           inlv.creation_date                creation_date,                 -- �쐬��
           inlv.last_updated_by              last_updated_by,               -- �ŏI�X�V��
           inlv.last_update_date             last_update_date,              -- �ŏI�X�V��
           inlv.last_update_login            last_update_login ,            -- �ŏI�X�V���O�C��
           inlv.request_id                   request_id,                    -- �v��ID
           inlv.program_application_id       program_application_id,        -- �A�v���P�[�V����ID
           inlv.program_id                   program_id,                    -- �v���O����ID
-- Modify 2009.09.29 Ver1.5 Start
--           inlv.program_update_date          program_update_date            -- �v���O�����X�V��
           inlv.program_update_date          program_update_date,           -- �v���O�����X�V��
           inlv.cutoff_date                  cutoff_date,                   -- ����
           inlv.num_of_cases                 num_of_cases,                  -- �P�[�X����
-- Modify 2009.11.02 Ver1.6 Start
--           inlv.medium_class                 medium_class                   -- �󒍃\�[�X
           inlv.medium_class                 medium_class,                  -- �󒍃\�[�X
           inlv.delivery_chain_code          delivery_chain_code            -- �[�i��`�F�[���R�[�h
-- Modify 2009.11.02 Ver1.6 End
-- Modify 2009.09.29 Ver1.5 End
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD START
          ,inlv.bms_header_data              bms_header_data                -- ���ʂa�l�r�w�b�_�f�[�^
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD END
-- Add 2019.07.26 Ver1.160 START
          ,inlv.tax_code                     tax_code                       -- �ŋ��R�[�h
-- Add 2019.07.26 Ver1.160 END
    FROM   (--�������׃f�[�^(AR�������) 
            SELECT /*+ FIRST_ROWS
-- Modify 2009.09.29 Ver1.5 Start
--                       LEADING(xih)
                       LEADING(xih rcta hzca hp_ship xxca hc_sold hp_sold hzsa rlli rlta rgda arta fnvd)
-- Modify 2009.09.29 Ver1.5 End
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U1)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_PK)
-- Modify 2009.09.29 Ver1.5 Start
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
-- Modify 2009.09.29 Ver1.5 End
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(rlta RA_CUSTOMER_TRX_LINES_N3)
                       INDEX(rgda RA_CUST_TRX_LINE_GL_DIST_N6)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(fnvd FND_LOOKUP_VALUES_U1)
                   */
                   xih.invoice_id                                 invoice_id,             -- �ꊇ������ID
                   NULL                                           note_line_id,           -- �`�[����No
                   hzca.account_number                            ship_cust_code,         -- �[�i��ڋq�R�[�h
-- Modify 2009.09.29 Ver1.5 Start
--                   hzca.party_id                                  ship_party_id,
                   hp_ship.party_name                             ship_cust_name,      -- �[�i��ڋq��
                   hp_ship.organization_name_phonetic             ship_cust_kana_name, -- �[�i��ڋq�J�i��
-- Modify 2009.09.29 Ver1.5 End
                   xxca.sale_base_code                            sold_location_code,     -- ���㋒�_�R�[�h
-- Modify 2009.09.29 Ver1.5 Start
                   hp_sold.party_name                             sold_location_name,     -- ���㋒�_��
-- Modify 2009.09.29 Ver1.5 End
                   xxca.store_code                                ship_shop_code,         -- �[�i��X�܃R�[�h
                   xxca.cust_store_name                           ship_shop_name,         -- �[�i��X��
                   xxca.vendor_machine_number                     vd_num,                 -- �����̔��@�ԍ�
                   NVL(fnvd.attribute1, '0')                      vd_cust_type,           -- VD�ڋq�敪
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no) inv_type,               -- �����敪
                   xxca.chain_store_code                          chain_shop_code,        -- �`�F�[���X�R�[�h
                   rgda.gl_date                                   delivery_date,          -- �[�i��
                   rlli.interface_line_attribute3                 slip_num,               -- �`�[�ԍ�
                   NULL                                           order_num,              -- �I�[�_�[NO
                   NULL                                           column_num,             -- �R����No
                   NULL                                           slip_type,              -- �`�[�敪
                   NULL                                           classify_type,          -- ���ދ敪
                   NULL                                           customer_dept_code,     -- ���q�l����R�[�h
                   NULL                                           customer_division_code, -- ���q�l�ۃR�[�h
-- Modify 2010.01.04 Ver1.9 Start
--                   NULL                                           sold_return_type,       -- ����ԕi�敪
                   cv_sold_return_type_ar                         sold_return_type,       -- ����ԕi�敪
-- Modify 2010.01.04 Ver1.9 End
                   NULL                                           nichiriu_by_way_type,   -- �j�`���E�o�R�敪
                   NULL                                           sale_type,              -- �����敪
                   NULL                                           direct_num,             -- ��No
                   NULL                                           po_date,                -- ������
                   rcta.trx_date                                  acceptance_date,        -- ������
                   NULL                                           item_code,              -- ���iCD
                   NULL                                           item_name,              -- ���i��
                   NULL                                           item_kana_name,         -- ���i�J�i��
                   NULL                                           policy_group,           -- ����Q�R�[�h
                   NULL                                           jan_code,               -- JAN�R�[�h
                   NULL                                           vessel_type,            -- �e��敪
                   NULL                                           vessel_type_name,       -- �e��敪��
                   NULL                                           vessel_group,           -- �e��Q
                   NULL                                           vessel_group_name,      -- �e��Q��
                   rlli.quantity_invoiced                         quantity,               -- ����
                   rlli.unit_selling_price                        unit_price,             -- �P��
                   rlli.quantity_invoiced                         dlv_qty,                      -- �[�i����
                   rlli.unit_selling_price                        dlv_unit_price,               -- �[�i�P��
                   NULL                                           dlv_uom_code,                 -- �[�i�P��
                   NULL                                           standard_uom_code,            -- ��P��
                   NULL                                           standard_unit_price_excluded, -- �Ŕ���P��
                   NULL                                           business_cost,                -- �c�ƌ���
                   rlta.extended_amount                           tax_amount,             -- ����ŋ��z
                   arta.tax_rate                                  tax_rate,               -- ����ŗ�
                   rlli.extended_amount                           ship_amount,            -- �[�i���z
                   DECODE(xih.tax_type,
                            cv_tax_div_outtax,   rlli.extended_amount,    -- �O�Ł@�F�Ŕ��z
                            cv_tax_div_notax,    rlli.extended_amount,    -- ��ېŁF�Ŕ��z
                            cv_tax_div_inslip,   rlli.extended_amount,    -- ����(�`�[)�F�Ŕ��z
                            rlli.extended_amount + rlta.extended_amount)  -- ����(�P��)�F�ō��z
                                                                  sold_amount,            -- ������z
                   NULL                                           red_black_slip_type,    -- �ԓ`���`�敪
                   rcta.customer_trx_id                           trx_id,                 -- ���ID
                   rcta.trx_number                                trx_number,             -- ����ԍ�
                   rcta.cust_trx_type_id                          cust_trx_type_id,       -- ����^�C�vID
                   rcta.batch_source_id                           batch_source_id,        -- ����\�[�XID
                   cn_created_by                                  created_by,             -- �쐬��
                   cd_creation_date                               creation_date,          -- �쐬��
                   cn_last_updated_by                             last_updated_by,        -- �ŏI�X�V��
                   cd_last_update_date                            last_update_date,       -- �ŏI�X�V��
                   cn_last_update_login                           last_update_login ,     -- �ŏI�X�V���O�C��
                   cn_request_id                                  request_id,             -- �v��ID
                   cn_program_application_id                      program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                  program_id,             -- �v���O����ID
-- Modify 2009.09.29 Ver1.5 Start
--                   cd_program_update_date                         program_update_date     -- �v���O�����X�V��
                   cd_program_update_date                         program_update_date,    -- �v���O�����X�V��
                   xih.cutoff_date                                cutoff_date,            -- ����
                   NULL                                           num_of_cases,           -- �P�[�X����
-- Modify 2009.11.02 Ver1.6 Start
--                   NULL                                           medium_class            -- �󒍃\�[�X
                   NULL                                           medium_class,           -- �󒍃\�[�X
                   xxca.delivery_chain_code                       delivery_chain_code     -- �[�i��`�F�[���R�[�h
-- Modify 2009.11.02 Ver1.6 End
-- Modify 2009.09.29 Ver1.5 End
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD START
                  ,NULL                                           bms_header_data         -- ���ʂa�l�r�w�b�_�f�[�^
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD END
-- Add 2019.07.26 Ver1.160 START
                  ,arta.tax_code                                  tax_code                -- �ŋ��R�[�h
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,               -- �A�h�I���������w�b�_
                   ra_customer_trx               rcta,              -- ����e�[�u��
-- Modify 2009.09.29 Ver1.5 Start
                   hz_parties                    hp_sold,           -- �p�[�e�B�[(���㋒�_)
                   hz_cust_accounts              hc_sold,           -- �ڋq�}�X�^(���㋒�_)
                   hz_parties                    hp_ship,           -- �p�[�e�B�[(�[����)
-- Modify 2009.09.29 Ver1.5 End
                   hz_cust_accounts              hzca,              -- �ڋq�}�X�^
                   xxcmm_cust_accounts           xxca,              -- �ڋq�ǉ����
                   hz_cust_acct_sites            hzsa,              -- �ڋq���ݒn
                   ra_customer_trx_lines         rlli,              -- �������(����)�e�[�u��
                   ra_customer_trx_lines         rlta,              -- �������(�Ŋz)�e�[�u��
                   ra_cust_trx_line_gl_dist      rgda,              -- �����v���e�[�u��
                   ar_vat_tax_all_b              arta,              -- �ŋ��}�X�^
                   fnd_lookup_values             fnvd               -- �N�C�b�N�R�[�h(VD�ڋq�敪)
            WHERE  xih.request_id            = gt_target_request_id       -- �^�[�Q�b�g�ƂȂ�v��ID
-- Modify 2012.11.06 Ver1.120 Start
            AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'2'(���)
            AND     ( xih.parallel_type       = gn_parallel_type ) )  -- �p���������s�敪����v
            OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'0'(�蓮)
            AND     ( xih.parallel_type      IS NULL ) ) )            -- �p���������s�敪��NULL
-- Modify 2012.11.06 Ver1.120 End
            AND    rcta.trx_date            <= xih.cutoff_date            -- �����
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- ������ڋqID
            AND    xih.org_id                = gn_org_id                      -- �g�DID
            AND    xih.set_of_books_id       = gn_set_book_id        -- ��v����ID
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)        -- �������ۗ��X�e�[�^�X
            AND    rcta.set_of_books_id = gn_set_book_id            -- ��v����ID
            AND    rcta.batch_source_id = gt_arinput_trx_source_id  -- ����\�[�X
            AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
-- Modify 2009.09.29 Ver1.5 Start
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- ���㋒�_�R�[�h
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- �p�[�e�B�[ID
            AND    hzca.party_id        = hp_ship.party_id           -- �p�[�e�B�[ID
-- Modify 2009.09.29 Ver1.5 End
            AND    rcta.ship_to_customer_id = xxca.customer_id(+)
            AND    hzca.cust_account_id = hzsa.cust_account_id(+)
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.customer_trx_id = rlta.customer_trx_id(+)
            AND    rlli.customer_trx_line_id = rlta.link_to_cust_trx_line_id(+)
            AND    rlli.line_type = cv_line_type_line
            AND    rlta.line_type(+) = cv_line_type_tax
            AND    rcta.customer_trx_id = rgda.customer_trx_id
            AND    rgda.account_class = cv_account_class_rec
            AND    rlta.vat_tax_id = arta.vat_tax_id
            AND    fnvd.lookup_type(+)  = cv_lookup_vd_class_type    -- �Q�ƃ^�C�v(�ėp����VD�Ώۏ�����)
            AND    fnvd.language(+)     = USERENV( 'LANG' )
            AND    fnvd.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnvd.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnvd.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fnvd.lookup_code(+)
              UNION ALL
            --�������׃f�[�^(�̔�����) 
            SELECT /*+ FIRST_ROWS
-- Modify 2009.12.02 Ver1.8 Start
-- Modify 2009.09.29 Ver1.5 Start
--                       LEADING(xih)
--                       LEADING(xih rcta hzca hp_ship xxca hc_sold hp_sold hzsa rlli xxeh xedh fdsc)
                       LEADING(xih rcta rlli xxeh hzca xxca hzsa xedh fdsc hp_ship hc_sold hp_sold)
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2009.12.02 Ver1.8 End
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
-- Modify 2009.12.02 Ver1.8 Start
--                       INDEX(hzca HZ_CUST_ACCOUNTS_U1)
--                       INDEX(xxca XXCMM_CUST_ACCOUNTS_PK)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U2)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_N06)
-- Modify 2009.12.02 Ver1.8 End
-- Modify 2009.09.29 Ver1.5 Start
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
-- Modify 2009.09.29 Ver1.5 End
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(xxeh XXCOS_SALES_EXP_HEADERS_PK)
                       INDEX(xxel XXCOS_SALES_EXP_LINES_N01)
                       INDEX(xedh XXCOS_EDI_HEADERS_N03)
                       INDEX(mtib MTL_SYSTEM_ITEMS_B_N1)
                       INDEX(xxib XXCMN_IMB_N02)
-- Modify 2009.12.02 Ver1.8 Start
                       USE_NL(hzca xxca)
-- Modify 2009.12.02 Ver1.8 End
                   */
                   xih.invoice_id                                  invoice_id,             -- �ꊇ������ID
                   xxel.dlv_invoice_line_number                    note_line_id,            -- �`�[����No
-- Modify 2009.12.02 Ver1.8 Start
--                   hzca.account_number                             ship_cust_code,          -- �[�i��ڋq�R�[�h
                   xxeh.ship_to_customer_code                     ship_cust_code,         -- �[�i��ڋq�R�[�h
-- Modify 2009.12.02 Ver1.8 End
-- Modify 2009.09.29 Ver1.5 Start
--                   hzca.party_id                                   ship_party_id,
                   hp_ship.party_name                              ship_cust_name,          -- �[�i��ڋq��
                   hp_ship.organization_name_phonetic              ship_cust_kana_name,     -- �[�i��ڋq�J�i��
-- Modify 2009.09.29 Ver1.5 End
                   xxca.sale_base_code                             sold_location_code,      -- ���㋒�_�R�[�h
-- Modify 2009.09.29 Ver1.5 Start
                   hp_sold.party_name                              sold_location_name,      -- ���㋒�_��
-- Modify 2009.09.29 Ver1.5 End
                   xxca.store_code                                 ship_shop_code,          -- �[�i��X�܃R�[�h
                   xxca.cust_store_name                            ship_shop_name,          -- �[�i��X��
                   xxca.vendor_machine_number                      vd_num,                  -- �����̔��@�ԍ�
                   NVL(fvdt.attribute1, '0')                       vd_cust_type,            -- VD�ڋq�敪
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no)  inv_type,                -- �����敪
                   xxca.chain_store_code                           chain_shop_code,         -- �`�F�[���X�R�[�h
                   xxeh.delivery_date                              delivery_date,           -- �[�i��
                   xxeh.dlv_invoice_number                         slip_num,                -- �`�[�ԍ�
                   xxeh.order_invoice_number                       order_num,               -- �I�[�_�[NO
                   xxel.column_no                                  column_num,              -- �R����No
                   xxeh.invoice_class                              slip_type,               -- �`�[�敪
                   xxeh.invoice_classification_code                classify_type,           -- ���ދ敪
                   xedh.other_party_department_code                customer_dept_code,      -- ���q�l����R�[�h
                   xedh.delivery_to_section_code                   customer_division_code,  -- ���q�l�ۃR�[�h
                   fdsc.attribute1                                 sold_return_type,        -- ����ԕi�敪
                   NULL                                            nichiriu_by_way_type,    -- �j�`���E�o�R�敪
                   fscl.attribute8                                 sale_type,               -- �����敪
                   xedh.opportunity_no                             direct_num,              -- ��No
                   xedh.order_date                                 po_date,                 -- ������
                   rcta.trx_date                                   acceptance_date,         -- ������
                   xxel.item_code                                  item_code,               -- ���iCD
                   mtib.description                                item_name,               -- ���i��
                   xxmb.item_name_alt                              item_kana_name,          -- ���i�J�i��
                   icmb.attribute2                                 policy_group,            -- ����Q�R�[�h
                   icmb.attribute21                                jan_code,                -- JAN�R�[�h
                   fnlv.attribute1                                 vessel_type,             -- �e��敪
                   fykn.meaning                                    vessel_type_name,        -- �e��敪��
                   xxib.vessel_group                               vessel_group,            -- �e��Q
                   fnlv.meaning                                    vessel_group_name,       -- �e��Q��
                   xxel.standard_qty                               quantity,                -- ����(�����)
                   xxel.standard_unit_price                        unit_price,              -- �P��(��P��)
                   xxel.dlv_qty                                    dlv_qty,                 -- �[�i����
                   xxel.dlv_unit_price                             dlv_unit_price,               -- �[�i�P��
                   xxel.dlv_uom_code                               dlv_uom_code,                 -- �[�i�P��
                   xxel.standard_uom_code                          standard_uom_code,            -- ��P��
                   xxel.standard_unit_price_excluded               standard_unit_price_excluded, -- �Ŕ���P��
                   xxel.business_cost                              business_cost,                -- �c�ƌ���
                   xxel.tax_amount                                 tax_amount,              -- ����ŋ��z
-- Modify 2019.07.26 Ver1.160 Start
--                   xxeh.tax_rate                                   tax_rate,                -- ����ŗ�
-- Modify Ver1.170 Start
--                   xxel.tax_rate                                   tax_rate,                -- ����ŗ�
                   NVL(xxel.tax_rate,xxeh.tax_rate)                tax_rate,                -- ����ŗ�
-- Modify Ver1.170 End
-- Modify 2019.07.26 Ver1.160 End
                   xxel.pure_amount                                ship_amount,             -- �[�i���z
                   xxel.sale_amount                                sold_amount,             -- ������z
                   NULL                                            red_black_slip_type,     -- �ԓ`���`�敪
                   rcta.customer_trx_id                            trx_id,                  -- ���ID
                   rcta.trx_number                                 trx_number,              -- ����ԍ�
                   rcta.cust_trx_type_id                           cust_trx_type_id,        -- ����^�C�vID
                   rcta.batch_source_id                            batch_source_id,         -- ����\�[�XID
                   cn_created_by                                   created_by,              -- �쐬��
                   cd_creation_date                                creation_date,           -- �쐬��
                   cn_last_updated_by                              last_updated_by,         -- �ŏI�X�V��
                   cd_last_update_date                             last_update_date,        -- �ŏI�X�V��
                   cn_last_update_login                            last_update_login ,      -- �ŏI�X�V���O�C��
                   cn_request_id                                   request_id,              -- �v��ID
                   cn_program_application_id                       program_application_id,  -- �A�v���P�[�V����ID
                   cn_program_id                                   program_id,              -- �v���O����ID
-- Modify 2009.09.29 Ver1.5 Start
--                   cd_program_update_date                          program_update_date      -- �v���O�����X�V��
                   cd_program_update_date                          program_update_date,     -- �v���O�����X�V��
                   xih.cutoff_date                                 cutoff_date,             -- ����
                   icmb.attribute11                                num_of_cases,            -- �P�[�X����
-- Modify 2009.11.02 Ver1.6 Start
--                   NVL( xedh.medium_class , cv_medium_class_mnl)   medium_class             -- �󒍃\�[�X
                   NVL( xedh.medium_class , cv_medium_class_mnl)   medium_class,            -- �󒍃\�[�X
                   xxca.delivery_chain_code                        delivery_chain_code      -- �[�i��`�F�[���R�[�h
-- Modify 2009.11.02 Ver1.6 End
-- Modify 2009.09.29 Ver1.5 End
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD START
                  ,xedh.bms_header_data                            bms_header_data          -- ���ʂa�l�r�w�b�_�f�[�^
-- 2011/10/11 A.Shirakawa Ver.1.110 ADD END
-- Add 2019.07.26 Ver1.160 START
-- Modify Ver1.170 Start
--                  ,xxel.tax_code                                   tax_code                 -- �ŋ��R�[�h
                  ,NVL(xxel.tax_code,xxeh.tax_code)                tax_code                 -- �ŋ��R�[�h
-- Modify Ver1.170 End
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,            -- �A�h�I���������w�b�_
                   ra_customer_trx               rcta,           -- ����e�[�u��
-- Modify 2009.09.29 Ver1.5 Start
                   hz_parties                    hp_sold,        -- �p�[�e�B�[(���㋒�_)
                   hz_cust_accounts              hc_sold,        -- �ڋq�}�X�^(���㋒�_)
                   hz_parties                    hp_ship,        -- �p�[�e�B�[(�[����)
-- Modify 2009.09.29 Ver1.5 End
                   hz_cust_accounts              hzca,           -- �ڋq�}�X�^
                   xxcmm_cust_accounts           xxca,           -- �ڋq�ǉ����
                   hz_cust_acct_sites            hzsa,           -- �ڋq���ݒn
                   ra_customer_trx_lines         rlli,           -- ������׃e�[�u��
                   xxcos_sales_exp_headers       xxeh,           -- �̔����уw�b�_�e�[�u��
                   xxcos_sales_exp_lines         xxel,           -- �̔����і��׃e�[�u��
                   xxcos_edi_headers             xedh,           -- EDI�w�b�_���e�[�u��
                   mtl_system_items_b            mtib,           -- �i�ڃ}�X�^
                   xxcmm_system_items_b          xxib,           -- Disc�i�ڃA�h�I��
                   fnd_lookup_values             fnlv,           -- �N�C�b�N�R�[�h(�e��Q)
                   fnd_lookup_values             fykn,           -- �N�C�b�N�R�[�h(�e��敪)
                   fnd_lookup_values             fdsc,           -- �N�C�b�N�R�[�h(�[�i�`�[�敪)
                   fnd_lookup_values             fscl,           -- �N�C�b�N�R�[�h(����敪)
                   fnd_lookup_values             fvdt,           -- �N�C�b�N�R�[�h(VD�ڋq�敪)
                   ic_item_mst_b                 icmb,           -- OPM�i�ڃ}�X�^
                   xxcmn_item_mst_b              xxmb            -- OPM�i�ڃA�h�I��
            WHERE  xih.request_id            = gt_target_request_id       -- �^�[�Q�b�g�ƂȂ�v��ID
-- Modify 2012.11.06 Ver1.120 Start
            AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'2'(���)
            AND     ( xih.parallel_type       = gn_parallel_type ) )  -- �p���������s�敪����v
            OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'0'(�蓮)
            AND     ( xih.parallel_type      IS NULL ) ) )            -- �p���������s�敪��NULL
-- Modify 2012.11.06 Ver1.120 End
            AND    rcta.trx_date            <= xih.cutoff_date            -- �����
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- ������ڋqID
            AND    xih.org_id                = gn_org_id                      -- �g�DID
            AND    xih.set_of_books_id       = gn_set_book_id        -- ��v����ID
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)         -- �������ۗ��X�e�[�^�X
            AND    rcta.set_of_books_id = gn_set_book_id             -- ��v����ID
            AND    rcta.batch_source_id != gt_arinput_trx_source_id  -- ����\�[�X(AR������͈ȊO)
-- Modify 2009.12.02 Ver1.8 Start
--            AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
            AND    xxeh.ship_to_customer_code = hzca.account_number
-- Modify 2009.12.02 Ver1.8 End
-- Modify 2009.09.29 Ver1.5 Start
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- ���㋒�_�R�[�h
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- �p�[�e�B�[ID
            AND    hzca.party_id        = hp_ship.party_id           -- �p�[�e�B�[ID
-- Modify 2009.09.29 Ver1.5 End
-- Modify 2009.12.02 Ver1.8 Start
--            AND    rcta.ship_to_customer_id = xxca.customer_id(+)
--            AND    hzca.cust_account_id = hzsa.cust_account_id(+)
            AND    xxeh.ship_to_customer_code = xxca.customer_code
            AND    hzca.cust_account_id = hzsa.cust_account_id
-- Modify 2009.12.02 Ver1.8 End
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.line_type = cv_line_type_line
-- 2019/09/19 Ver1.180 ADD Start
            AND    rlli.customer_trx_line_id = (  SELECT MIN(rctla.customer_trx_line_id) customer_trx_line_id
                                                  FROM   ra_customer_trx_lines  rctla
                                                  WHERE  rctla.customer_trx_id           = rcta.customer_trx_id
                                                  AND    rctla.line_type                 = cv_line_type_line
                                                  AND    rctla.interface_line_attribute7 = rlli.interface_line_attribute7  )
-- 2019/09/19 Ver1.180 ADD End
            AND    rlli.interface_line_attribute7 = xxeh.sales_exp_header_id  -- �̔����уw�b�_����ID
            AND    xxeh.sales_exp_header_id = xxel.sales_exp_header_id
-- 2019/09/19 Ver1.180 ADD Start
            AND    xxel.goods_prod_cls IS NOT NULL
-- 2019/09/19 Ver1.180 ADD End
-- Add 2010.10.19 Ver1.100 Start
-- 2019/09/19 Ver1.180 DEL Start
--            AND   ((rlli.interface_line_attribute8 IS NULL)
--               OR  (rlli.interface_line_attribute8 = xxel.goods_prod_cls))    -- �i�ڋ敪
-- 2019/09/19 Ver1.180 DEL End
-- Add 2010.10.19 Ver1.100 End
            AND    xxeh.order_connection_number = xedh.order_connection_number(+)
            AND    xxel.item_code = mtib.segment1(+)
            AND    mtib.organization_id(+) = gt_mtl_organization_id  -- �i�ڃ}�X�^�g�DID
            AND    fdsc.lookup_type(+)  = cv_lookup_slip_class    -- �Q�ƃ^�C�v(�[�i�`�[�敪)
            AND    fdsc.language(+)     = USERENV( 'LANG' )
            AND    fdsc.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fdsc.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fdsc.end_date_active(+),   gd_process_date ) )
            AND    xxeh.dlv_invoice_class = fdsc.lookup_code(+)
            AND    fscl.lookup_type(+)  = cv_lookup_sale_class    -- �Q�ƃ^�C�v(����敪)
            AND    fscl.language(+)     = USERENV( 'LANG' )
            AND    fscl.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fscl.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fscl.end_date_active(+),   gd_process_date ) )
            AND    xxel.sales_class = fscl.lookup_code(+)
            AND    mtib.segment1 = icmb.item_no(+)
            AND    icmb.item_id  = xxmb.item_id(+)
-- Del 2016.03.02 Ver1.150 Start
--            AND    xxmb.active_flag(+) = 'Y'
-- Del 2016.03.02 Ver1.150 End
            AND    xih.cutoff_date >= NVL(TRUNC(xxmb.start_date_active), xih.cutoff_date)
            AND    xih.cutoff_date <= NVL(xxmb.end_date_active, xih.cutoff_date)
            AND    icmb.item_id = xxib.item_id(+)
            AND    fnlv.lookup_type(+)  = cv_lookup_itm_yokigun   -- �Q�ƃ^�C�v(�e��Q)
            AND    fnlv.language(+)     = USERENV( 'LANG' )
            AND    fnlv.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
            AND    xxib.vessel_group = fnlv.lookup_code(+)
            AND    fykn.lookup_type(+)  = cv_lookup_itm_yokikubun   -- �Q�ƃ^�C�v(�e��敪)
            AND    fykn.language(+)     = USERENV( 'LANG' )
            AND    fykn.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fykn.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fykn.end_date_active(+),   gd_process_date ) )
            AND    fnlv.attribute1 = fykn.lookup_code(+)
            AND    fvdt.lookup_type(+)  = cv_lookup_vd_class_type    -- �Q�ƃ^�C�v(�ėp����VD�Ώۏ�����)
            AND    fvdt.language(+)     = USERENV( 'LANG' )
            AND    fvdt.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fvdt.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fvdt.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fvdt.lookup_code(+)
-- Modify 2009.09.29 Ver1.5 Start
--          )                inlv,
--          hz_parties       ship,   -- �p�[�e�B�[(�[�i��)
--          hz_parties       sold,   -- �p�[�e�B�[(���㋒�_)
--          hz_cust_accounts soldca  -- �ڋq�}�X�^
--    WHERE inlv.ship_party_id      = ship.party_id
--      AND inlv.sold_location_code = soldca.account_number
--      AND soldca.party_id         = sold.party_id
          )                inlv
-- Modify 2009.09.29 Ver1.5 End
    ;
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
    --�蓮���s�p
    CURSOR main_data_manual_cur 
    IS
    SELECT inlv.invoice_id                   invoice_id,                    -- �ꊇ������ID
           TO_NUMBER(TO_CHAR(SYSDATE, 'yyyymmddhh24miss') || TO_CHAR(ROWNUM))  invoice_detail_num,  -- �ꊇ����������No
           inlv.note_line_id                 note_line_id,                  -- �`�[����No
           inlv.ship_cust_code               ship_cust_code,                -- �[�i��ڋq�R�[�h
           inlv.ship_cust_name               ship_cust_name,                -- �[�i��ڋq��
           inlv.ship_cust_kana_name          ship_cust_kana_name,           -- �[�i��ڋq�J�i��
           inlv.sold_location_code           sold_location_code,            -- ���㋒�_�R�[�h
           inlv.sold_location_name           sold_location_name,            -- ���㋒�_��
           inlv.ship_shop_code               ship_shop_code,                -- �[�i��X�܃R�[�h
           inlv.ship_shop_name               ship_shop_name,                -- �[�i��X��
           inlv.vd_num                       vd_num,                        -- �����̔��@�ԍ�
           inlv.vd_cust_type                 vd_cust_type,                  -- VD�ڋq�敪
           inlv.inv_type                     inv_type,                      -- �����敪
           inlv.chain_shop_code              chain_shop_code,               -- �`�F�[���X�R�[�h
           inlv.delivery_date                delivery_date,                 -- �[�i��
           inlv.slip_num                     slip_num,                      -- �`�[�ԍ�
           inlv.order_num                    order_num,                     -- �I�[�_�[NO
           inlv.column_num                   column_num,                    -- �R����No
           inlv.slip_type                    slip_type,                     -- �`�[�敪
           inlv.classify_type                classify_type,                 -- ���ދ敪
           inlv.customer_dept_code           customer_dept_code,            -- ���q�l����R�[�h
           inlv.customer_division_code       customer_division_code,        -- ���q�l�ۃR�[�h
           inlv.sold_return_type             sold_return_type,              -- ����ԕi�敪
           inlv.nichiriu_by_way_type         nichiriu_by_way_type,          -- �j�`���E�o�R�敪
           inlv.sale_type                    sale_type,                     -- �����敪
           inlv.direct_num                   direct_num,                    -- ��No
           inlv.po_date                      po_date,                       -- ������
           inlv.acceptance_date              acceptance_date,               -- ������
           inlv.item_code                    item_code,                     -- ���iCD
           inlv.item_name                    item_name,                     -- ���i��
           inlv.item_kana_name               item_kana_name,                -- ���i�J�i��
           inlv.policy_group                 policy_group,                  -- ����Q�R�[�h
           inlv.jan_code                     jan_code,                      -- JAN�R�[�h
           inlv.vessel_type                  vessel_type,                   -- �e��敪
           inlv.vessel_type_name             vessel_type_name,              -- �e��敪��
           inlv.vessel_group                 vessel_group,                  -- �e��Q
           inlv.vessel_group_name            vessel_group_name,             -- �e��Q��
           inlv.quantity                     quantity,                      -- ����
           inlv.unit_price                   unit_price,                    -- �P��
           inlv.dlv_qty                      dlv_qty,                       -- �[�i����
           inlv.dlv_unit_price               dlv_unit_price,                -- �[�i�P��
           inlv.dlv_uom_code                 dlv_uom_code,                  -- �[�i�P��
           inlv.standard_uom_code            standard_uom_code,             -- ��P��
           inlv.standard_unit_price_excluded standard_unit_price_excluded,  -- �Ŕ���P��
           inlv.business_cost                business_cost,                 -- �c�ƌ���
           inlv.tax_amount                   tax_amount,                    -- ����ŋ��z
           inlv.tax_rate                     tax_rate,                      -- ����ŗ�
           inlv.ship_amount                  ship_amount,                   -- �[�i���z
           inlv.sold_amount                  sold_amount,                   -- ������z
           inlv.red_black_slip_type          red_black_slip_type,           -- �ԓ`���`�敪
           inlv.trx_id                       trx_id,                        -- ���ID
           inlv.trx_number                   trx_number,                    -- ����ԍ�
           inlv.cust_trx_type_id             cust_trx_type_id,              -- ����^�C�vID
           inlv.batch_source_id              batch_source_id,               -- ����\�[�XID
           inlv.created_by                   created_by,                    -- �쐬��
           inlv.creation_date                creation_date,                 -- �쐬��
           inlv.last_updated_by              last_updated_by,               -- �ŏI�X�V��
           inlv.last_update_date             last_update_date,              -- �ŏI�X�V��
           inlv.last_update_login            last_update_login ,            -- �ŏI�X�V���O�C��
           inlv.request_id                   request_id,                    -- �v��ID
           inlv.program_application_id       program_application_id,        -- �A�v���P�[�V����ID
           inlv.program_id                   program_id,                    -- �v���O����ID
           inlv.program_update_date          program_update_date,           -- �v���O�����X�V��
           inlv.cutoff_date                  cutoff_date,                   -- ����
           inlv.num_of_cases                 num_of_cases,                  -- �P�[�X����
           inlv.medium_class                 medium_class,                  -- �󒍃\�[�X
           inlv.delivery_chain_code          delivery_chain_code            -- �[�i��`�F�[���R�[�h
          ,inlv.bms_header_data              bms_header_data                -- ���ʂa�l�r�w�b�_�f�[�^
-- Add 2019.07.26 Ver1.160 START
          ,inlv.tax_code                     tax_code                       -- �ŋ��R�[�h
-- Add 2019.07.26 Ver1.160 END
    FROM   (--�������׃f�[�^(AR�������) 
            SELECT /*+ FIRST_ROWS
                       LEADING(xih rcta hzca hp_ship xxca hc_sold hp_sold hzsa rlli rlta rgda arta fnvd)
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U1)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_PK)
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(rlta RA_CUSTOMER_TRX_LINES_N3)
                       INDEX(rgda RA_CUST_TRX_LINE_GL_DIST_N6)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(fnvd FND_LOOKUP_VALUES_U1)
                   */
                   xih.invoice_id                                 invoice_id,             -- �ꊇ������ID
                   NULL                                           note_line_id,           -- �`�[����No
                   hzca.account_number                            ship_cust_code,         -- �[�i��ڋq�R�[�h
                   hp_ship.party_name                             ship_cust_name,      -- �[�i��ڋq��
                   hp_ship.organization_name_phonetic             ship_cust_kana_name, -- �[�i��ڋq�J�i��
                   xxca.sale_base_code                            sold_location_code,     -- ���㋒�_�R�[�h
                   hp_sold.party_name                             sold_location_name,     -- ���㋒�_��
                   xxca.store_code                                ship_shop_code,         -- �[�i��X�܃R�[�h
                   xxca.cust_store_name                           ship_shop_name,         -- �[�i��X��
                   xxca.vendor_machine_number                     vd_num,                 -- �����̔��@�ԍ�
                   NVL(fnvd.attribute1, '0')                      vd_cust_type,           -- VD�ڋq�敪
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no) inv_type,               -- �����敪
                   xxca.chain_store_code                          chain_shop_code,        -- �`�F�[���X�R�[�h
                   rgda.gl_date                                   delivery_date,          -- �[�i��
                   rlli.interface_line_attribute3                 slip_num,               -- �`�[�ԍ�
                   NULL                                           order_num,              -- �I�[�_�[NO
                   NULL                                           column_num,             -- �R����No
                   NULL                                           slip_type,              -- �`�[�敪
                   NULL                                           classify_type,          -- ���ދ敪
                   NULL                                           customer_dept_code,     -- ���q�l����R�[�h
                   NULL                                           customer_division_code, -- ���q�l�ۃR�[�h
                   cv_sold_return_type_ar                         sold_return_type,       -- ����ԕi�敪
                   NULL                                           nichiriu_by_way_type,   -- �j�`���E�o�R�敪
                   NULL                                           sale_type,              -- �����敪
                   NULL                                           direct_num,             -- ��No
                   NULL                                           po_date,                -- ������
                   rcta.trx_date                                  acceptance_date,        -- ������
                   NULL                                           item_code,              -- ���iCD
                   NULL                                           item_name,              -- ���i��
                   NULL                                           item_kana_name,         -- ���i�J�i��
                   NULL                                           policy_group,           -- ����Q�R�[�h
                   NULL                                           jan_code,               -- JAN�R�[�h
                   NULL                                           vessel_type,            -- �e��敪
                   NULL                                           vessel_type_name,       -- �e��敪��
                   NULL                                           vessel_group,           -- �e��Q
                   NULL                                           vessel_group_name,      -- �e��Q��
                   rlli.quantity_invoiced                         quantity,               -- ����
                   rlli.unit_selling_price                        unit_price,             -- �P��
                   rlli.quantity_invoiced                         dlv_qty,                      -- �[�i����
                   rlli.unit_selling_price                        dlv_unit_price,               -- �[�i�P��
                   NULL                                           dlv_uom_code,                 -- �[�i�P��
                   NULL                                           standard_uom_code,            -- ��P��
                   NULL                                           standard_unit_price_excluded, -- �Ŕ���P��
                   NULL                                           business_cost,                -- �c�ƌ���
                   rlta.extended_amount                           tax_amount,             -- ����ŋ��z
                   arta.tax_rate                                  tax_rate,               -- ����ŗ�
                   rlli.extended_amount                           ship_amount,            -- �[�i���z
                   DECODE(xih.tax_type,
                            cv_tax_div_outtax,   rlli.extended_amount,    -- �O�Ł@�F�Ŕ��z
                            cv_tax_div_notax,    rlli.extended_amount,    -- ��ېŁF�Ŕ��z
                            cv_tax_div_inslip,   rlli.extended_amount,    -- ����(�`�[)�F�Ŕ��z
                            rlli.extended_amount + rlta.extended_amount)  -- ����(�P��)�F�ō��z
                                                                  sold_amount,            -- ������z
                   NULL                                           red_black_slip_type,    -- �ԓ`���`�敪
                   rcta.customer_trx_id                           trx_id,                 -- ���ID
                   rcta.trx_number                                trx_number,             -- ����ԍ�
                   rcta.cust_trx_type_id                          cust_trx_type_id,       -- ����^�C�vID
                   rcta.batch_source_id                           batch_source_id,        -- ����\�[�XID
                   cn_created_by                                  created_by,             -- �쐬��
                   cd_creation_date                               creation_date,          -- �쐬��
                   cn_last_updated_by                             last_updated_by,        -- �ŏI�X�V��
                   cd_last_update_date                            last_update_date,       -- �ŏI�X�V��
                   cn_last_update_login                           last_update_login ,     -- �ŏI�X�V���O�C��
                   cn_request_id                                  request_id,             -- �v��ID
                   cn_program_application_id                      program_application_id, -- �A�v���P�[�V����ID
                   cn_program_id                                  program_id,             -- �v���O����ID
                   cd_program_update_date                         program_update_date,    -- �v���O�����X�V��
                   xih.cutoff_date                                cutoff_date,            -- ����
                   NULL                                           num_of_cases,           -- �P�[�X����
                   NULL                                           medium_class,           -- �󒍃\�[�X
                   xxca.delivery_chain_code                       delivery_chain_code     -- �[�i��`�F�[���R�[�h
                  ,NULL                                           bms_header_data         -- ���ʂa�l�r�w�b�_�f�[�^
-- Add 2019.07.26 Ver1.160 START
                  ,arta.tax_code                                  tax_code                -- �ŋ��R�[�h
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,               -- �A�h�I���������w�b�_
                   ra_customer_trx               rcta,              -- ����e�[�u��
                   hz_parties                    hp_sold,           -- �p�[�e�B�[(���㋒�_)
                   hz_cust_accounts              hc_sold,           -- �ڋq�}�X�^(���㋒�_)
                   hz_parties                    hp_ship,           -- �p�[�e�B�[(�[����)
                   hz_cust_accounts              hzca,              -- �ڋq�}�X�^
                   xxcmm_cust_accounts           xxca,              -- �ڋq�ǉ����
                   hz_cust_acct_sites            hzsa,              -- �ڋq���ݒn
                   ra_customer_trx_lines         rlli,              -- �������(����)�e�[�u��
                   ra_customer_trx_lines         rlta,              -- �������(�Ŋz)�e�[�u��
                   ra_cust_trx_line_gl_dist      rgda,              -- �����v���e�[�u��
                   ar_vat_tax_all_b              arta,              -- �ŋ��}�X�^
                   fnd_lookup_values             fnvd               -- �N�C�b�N�R�[�h(VD�ڋq�敪)
            WHERE  xih.request_id            = gt_target_request_id       -- �^�[�Q�b�g�ƂȂ�v��ID
            AND    rcta.trx_date            <= xih.cutoff_date            -- �����
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- ������ڋqID
            AND    xih.org_id                = gn_org_id                      -- �g�DID
            AND    xih.set_of_books_id       = gn_set_book_id        -- ��v����ID
-- Modify 2013.06.10 Ver1.140 Start
            AND    xih.inv_creation_flag     = cv_inv_creation_flag  --�����쐬�Ώۃt���O
-- Modify 2013.06.10 Ver1.140 End
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)        -- �������ۗ��X�e�[�^�X
            AND    rcta.set_of_books_id = gn_set_book_id            -- ��v����ID
            AND    rcta.batch_source_id = gt_arinput_trx_source_id  -- ����\�[�X
            AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- ���㋒�_�R�[�h
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- �p�[�e�B�[ID
            AND    hzca.party_id        = hp_ship.party_id           -- �p�[�e�B�[ID
            AND    rcta.ship_to_customer_id = xxca.customer_id(+)
            AND    hzca.cust_account_id = hzsa.cust_account_id(+)
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.customer_trx_id = rlta.customer_trx_id(+)
            AND    rlli.customer_trx_line_id = rlta.link_to_cust_trx_line_id(+)
            AND    rlli.line_type = cv_line_type_line
            AND    rlta.line_type(+) = cv_line_type_tax
            AND    rcta.customer_trx_id = rgda.customer_trx_id
            AND    rgda.account_class = cv_account_class_rec
            AND    rlta.vat_tax_id = arta.vat_tax_id
            AND    fnvd.lookup_type(+)  = cv_lookup_vd_class_type    -- �Q�ƃ^�C�v(�ėp����VD�Ώۏ�����)
            AND    fnvd.language(+)     = USERENV( 'LANG' )
            AND    fnvd.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnvd.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnvd.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fnvd.lookup_code(+)
            AND    EXISTS (
                     -- �����w�b�_�f�[�^�쐬�p�����[�^������ڋq�ɕR�t���[�i��ڋq�������ΏۂƂ���
                     SELECT  'X'
                     FROM    hz_cust_acct_relate    bill_hcar
                            ,(
                       SELECT  bill_hzca.account_number    bill_account_number
                              ,ship_hzca.account_number    ship_account_number
                              ,bill_hzca.cust_account_id   bill_account_id
                              ,ship_hzca.cust_account_id   ship_account_id
                       FROM    hz_cust_accounts          bill_hzca
                              ,hz_cust_acct_sites        bill_hzsa
                              ,hz_cust_site_uses         bill_hsua
                              ,hz_cust_accounts          ship_hzca
                              ,hz_cust_acct_sites        ship_hasa
                              ,hz_cust_site_uses         ship_hsua
                       WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
                       AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
                       AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
                       AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
                       AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
                       AND     ship_hzca.customer_class_code = '10'
                       AND     bill_hsua.site_use_code = 'BILL_TO'
                       AND     bill_hsua.status = 'A'
                       AND     ship_hsua.status = 'A'
                     )  ship_cust_info
                     WHERE   hzca.cust_account_id = ship_cust_info.ship_account_id
                     AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
                     AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
                     AND     bill_hcar.attribute1(+) = '1'
                     AND     bill_hcar.status(+)     = 'A'
                     AND     ship_cust_info.bill_account_number = gt_bill_acct_code
                   )
              UNION ALL
            --�������׃f�[�^(�̔�����) 
            SELECT /*+ FIRST_ROWS
                       LEADING(xih rcta rlli xxeh hzca xxca hzsa xedh fdsc hp_ship hc_sold hp_sold)
                       INDEX(xih  XXCFR_INVOICE_HEADERS_N02)
                       INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
                       INDEX(hzca HZ_CUST_ACCOUNTS_U2)
                       INDEX(xxca XXCMM_CUST_ACCOUNTS_N06)
                       INDEX(hp_ship HZ_PARTIES_U1)
                       INDEX(hc_sold HZ_CUST_ACCOUNTS_U2)
                       INDEX(hp_sold HZ_PARTIES_U1)
                       INDEX(hzsa HZ_CUST_ACCT_SITES_N2)
                       INDEX(rlli RA_CUSTOMER_TRX_LINES_N2)
                       INDEX(arta AR_VAT_TAX_ALL_B_U1)
                       INDEX(xxeh XXCOS_SALES_EXP_HEADERS_PK)
                       INDEX(xxel XXCOS_SALES_EXP_LINES_N01)
                       INDEX(xedh XXCOS_EDI_HEADERS_N03)
                       INDEX(mtib MTL_SYSTEM_ITEMS_B_N1)
                       INDEX(xxib XXCMN_IMB_N02)
                       USE_NL(hzca xxca)
                   */
                   xih.invoice_id                                  invoice_id,             -- �ꊇ������ID
                   xxel.dlv_invoice_line_number                    note_line_id,            -- �`�[����No
                   xxeh.ship_to_customer_code                     ship_cust_code,         -- �[�i��ڋq�R�[�h
                   hp_ship.party_name                              ship_cust_name,          -- �[�i��ڋq��
                   hp_ship.organization_name_phonetic              ship_cust_kana_name,     -- �[�i��ڋq�J�i��
                   xxca.sale_base_code                             sold_location_code,      -- ���㋒�_�R�[�h
                   hp_sold.party_name                              sold_location_name,      -- ���㋒�_��
                   xxca.store_code                                 ship_shop_code,          -- �[�i��X�܃R�[�h
                   xxca.cust_store_name                            ship_shop_name,          -- �[�i��X��
                   xxca.vendor_machine_number                      vd_num,                  -- �����̔��@�ԍ�
                   NVL(fvdt.attribute1, '0')                       vd_cust_type,            -- VD�ڋq�敪
                   DECODE(rcta.attribute7,
                            cv_inv_hold_status_r, cv_inv_type_re
                                                , cv_inv_type_no)  inv_type,                -- �����敪
                   xxca.chain_store_code                           chain_shop_code,         -- �`�F�[���X�R�[�h
                   xxeh.delivery_date                              delivery_date,           -- �[�i��
                   xxeh.dlv_invoice_number                         slip_num,                -- �`�[�ԍ�
                   xxeh.order_invoice_number                       order_num,               -- �I�[�_�[NO
                   xxel.column_no                                  column_num,              -- �R����No
                   xxeh.invoice_class                              slip_type,               -- �`�[�敪
                   xxeh.invoice_classification_code                classify_type,           -- ���ދ敪
                   xedh.other_party_department_code                customer_dept_code,      -- ���q�l����R�[�h
                   xedh.delivery_to_section_code                   customer_division_code,  -- ���q�l�ۃR�[�h
                   fdsc.attribute1                                 sold_return_type,        -- ����ԕi�敪
                   NULL                                            nichiriu_by_way_type,    -- �j�`���E�o�R�敪
                   fscl.attribute8                                 sale_type,               -- �����敪
                   xedh.opportunity_no                             direct_num,              -- ��No
                   xedh.order_date                                 po_date,                 -- ������
                   rcta.trx_date                                   acceptance_date,         -- ������
                   xxel.item_code                                  item_code,               -- ���iCD
                   mtib.description                                item_name,               -- ���i��
                   xxmb.item_name_alt                              item_kana_name,          -- ���i�J�i��
                   icmb.attribute2                                 policy_group,            -- ����Q�R�[�h
                   icmb.attribute21                                jan_code,                -- JAN�R�[�h
                   fnlv.attribute1                                 vessel_type,             -- �e��敪
                   fykn.meaning                                    vessel_type_name,        -- �e��敪��
                   xxib.vessel_group                               vessel_group,            -- �e��Q
                   fnlv.meaning                                    vessel_group_name,       -- �e��Q��
                   xxel.standard_qty                               quantity,                -- ����(�����)
                   xxel.standard_unit_price                        unit_price,              -- �P��(��P��)
                   xxel.dlv_qty                                    dlv_qty,                 -- �[�i����
                   xxel.dlv_unit_price                             dlv_unit_price,               -- �[�i�P��
                   xxel.dlv_uom_code                               dlv_uom_code,                 -- �[�i�P��
                   xxel.standard_uom_code                          standard_uom_code,            -- ��P��
                   xxel.standard_unit_price_excluded               standard_unit_price_excluded, -- �Ŕ���P��
                   xxel.business_cost                              business_cost,                -- �c�ƌ���
                   xxel.tax_amount                                 tax_amount,              -- ����ŋ��z
-- Modify 2019.07.26 Ver1.160 Start
--                   xxeh.tax_rate                                   tax_rate,                -- ����ŗ�
-- Modify Ver1.170 Start
--                   xxel.tax_rate                                   tax_rate,                -- ����ŗ�
                   NVL(xxel.tax_rate,xxeh.tax_rate)                tax_rate,                -- ����ŗ�
-- Modify Ver1.170 End
-- Modify 2019.07.26 Ver1.160 End
                   xxel.pure_amount                                ship_amount,             -- �[�i���z
                   xxel.sale_amount                                sold_amount,             -- ������z
                   NULL                                            red_black_slip_type,     -- �ԓ`���`�敪
                   rcta.customer_trx_id                            trx_id,                  -- ���ID
                   rcta.trx_number                                 trx_number,              -- ����ԍ�
                   rcta.cust_trx_type_id                           cust_trx_type_id,        -- ����^�C�vID
                   rcta.batch_source_id                            batch_source_id,         -- ����\�[�XID
                   cn_created_by                                   created_by,              -- �쐬��
                   cd_creation_date                                creation_date,           -- �쐬��
                   cn_last_updated_by                              last_updated_by,         -- �ŏI�X�V��
                   cd_last_update_date                             last_update_date,        -- �ŏI�X�V��
                   cn_last_update_login                            last_update_login ,      -- �ŏI�X�V���O�C��
                   cn_request_id                                   request_id,              -- �v��ID
                   cn_program_application_id                       program_application_id,  -- �A�v���P�[�V����ID
                   cn_program_id                                   program_id,              -- �v���O����ID
                   cd_program_update_date                          program_update_date,     -- �v���O�����X�V��
                   xih.cutoff_date                                 cutoff_date,             -- ����
                   icmb.attribute11                                num_of_cases,            -- �P�[�X����
                   NVL( xedh.medium_class , cv_medium_class_mnl)   medium_class,            -- �󒍃\�[�X
                   xxca.delivery_chain_code                        delivery_chain_code      -- �[�i��`�F�[���R�[�h
                  ,xedh.bms_header_data                            bms_header_data          -- ���ʂa�l�r�w�b�_�f�[�^
-- Add 2019.07.26 Ver1.160 START
-- Modify Ver1.170 Start
--                  ,xxel.tax_code                                   tax_code                 -- �ŋ��R�[�h
                  ,NVL(xxel.tax_code,xxeh.tax_code)                tax_code                 -- �ŋ��R�[�h
-- Modify Ver1.170 End
-- Add 2019.07.26 Ver1.160 END
            FROM   
                   xxcfr_invoice_headers         xih,            -- �A�h�I���������w�b�_
                   ra_customer_trx               rcta,           -- ����e�[�u��
                   hz_parties                    hp_sold,        -- �p�[�e�B�[(���㋒�_)
                   hz_cust_accounts              hc_sold,        -- �ڋq�}�X�^(���㋒�_)
                   hz_parties                    hp_ship,        -- �p�[�e�B�[(�[����)
                   hz_cust_accounts              hzca,           -- �ڋq�}�X�^
                   xxcmm_cust_accounts           xxca,           -- �ڋq�ǉ����
                   hz_cust_acct_sites            hzsa,           -- �ڋq���ݒn
                   ra_customer_trx_lines         rlli,           -- ������׃e�[�u��
                   xxcos_sales_exp_headers       xxeh,           -- �̔����уw�b�_�e�[�u��
                   xxcos_sales_exp_lines         xxel,           -- �̔����і��׃e�[�u��
                   xxcos_edi_headers             xedh,           -- EDI�w�b�_���e�[�u��
                   mtl_system_items_b            mtib,           -- �i�ڃ}�X�^
                   xxcmm_system_items_b          xxib,           -- Disc�i�ڃA�h�I��
                   fnd_lookup_values             fnlv,           -- �N�C�b�N�R�[�h(�e��Q)
                   fnd_lookup_values             fykn,           -- �N�C�b�N�R�[�h(�e��敪)
                   fnd_lookup_values             fdsc,           -- �N�C�b�N�R�[�h(�[�i�`�[�敪)
                   fnd_lookup_values             fscl,           -- �N�C�b�N�R�[�h(����敪)
                   fnd_lookup_values             fvdt,           -- �N�C�b�N�R�[�h(VD�ڋq�敪)
                   ic_item_mst_b                 icmb,           -- OPM�i�ڃ}�X�^
                   xxcmn_item_mst_b              xxmb            -- OPM�i�ڃA�h�I��
            WHERE  xih.request_id            = gt_target_request_id       -- �^�[�Q�b�g�ƂȂ�v��ID
            AND    rcta.trx_date            <= xih.cutoff_date            -- �����
            AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- ������ڋqID
            AND    xih.org_id                = gn_org_id                      -- �g�DID
            AND    xih.set_of_books_id       = gn_set_book_id        -- ��v����ID
-- Modify 2013.06.10 Ver1.140 Start
            AND    xih.inv_creation_flag     = cv_inv_creation_flag  --�����쐬�Ώۃt���O
-- Modify 2013.06.10 Ver1.140 End
            AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                       cv_inv_hold_status_r)         -- �������ۗ��X�e�[�^�X
            AND    rcta.set_of_books_id = gn_set_book_id             -- ��v����ID
            AND    rcta.batch_source_id != gt_arinput_trx_source_id  -- ����\�[�X(AR������͈ȊO)
            AND    xxeh.ship_to_customer_code = hzca.account_number
            AND    xxca.sale_base_code  = hc_sold.account_number(+)  -- ���㋒�_�R�[�h
            AND    hc_sold.party_id     = hp_sold.party_id(+)        -- �p�[�e�B�[ID
            AND    hzca.party_id        = hp_ship.party_id           -- �p�[�e�B�[ID
            AND    xxeh.ship_to_customer_code = xxca.customer_code
            AND    hzca.cust_account_id = hzsa.cust_account_id
            AND    rcta.customer_trx_id = rlli.customer_trx_id
            AND    rlli.line_type = cv_line_type_line
-- 2019/09/19 Ver1.180 ADD Start
            AND    rlli.customer_trx_line_id = (  SELECT MIN(rctla.customer_trx_line_id) customer_trx_line_id
                                                  FROM   ra_customer_trx_lines  rctla
                                                  WHERE  rctla.customer_trx_id           = rcta.customer_trx_id
                                                  AND    rctla.line_type                 = cv_line_type_line
                                                  AND    rctla.interface_line_attribute7 = rlli.interface_line_attribute7  )
-- 2019/09/19 Ver1.180 ADD End
            AND    rlli.interface_line_attribute7 = xxeh.sales_exp_header_id  -- �̔����уw�b�_����ID
            AND    xxeh.sales_exp_header_id = xxel.sales_exp_header_id
-- 2019/09/19 Ver1.180 ADD Start
            AND    xxel.goods_prod_cls IS NOT NULL
-- 2019/09/19 Ver1.180 ADD End
-- 2019/09/19 Ver1.180 DEL Start
--            AND   ((rlli.interface_line_attribute8 IS NULL)
--               OR  (rlli.interface_line_attribute8 = xxel.goods_prod_cls))    -- �i�ڋ敪
-- 2019/09/19 Ver1.180 DEL End
            AND    xxeh.order_connection_number = xedh.order_connection_number(+)
            AND    xxel.item_code = mtib.segment1(+)
            AND    mtib.organization_id(+) = gt_mtl_organization_id  -- �i�ڃ}�X�^�g�DID
            AND    fdsc.lookup_type(+)  = cv_lookup_slip_class    -- �Q�ƃ^�C�v(�[�i�`�[�敪)
            AND    fdsc.language(+)     = USERENV( 'LANG' )
            AND    fdsc.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fdsc.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fdsc.end_date_active(+),   gd_process_date ) )
            AND    xxeh.dlv_invoice_class = fdsc.lookup_code(+)
            AND    fscl.lookup_type(+)  = cv_lookup_sale_class    -- �Q�ƃ^�C�v(����敪)
            AND    fscl.language(+)     = USERENV( 'LANG' )
            AND    fscl.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fscl.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fscl.end_date_active(+),   gd_process_date ) )
            AND    xxel.sales_class = fscl.lookup_code(+)
            AND    mtib.segment1 = icmb.item_no(+)
            AND    icmb.item_id  = xxmb.item_id(+)
-- Del 2016.03.02 Ver1.150 Start
--            AND    xxmb.active_flag(+) = 'Y'
-- Del 2016.03.02 Ver1.150 End
            AND    xih.cutoff_date >= NVL(TRUNC(xxmb.start_date_active), xih.cutoff_date)
            AND    xih.cutoff_date <= NVL(xxmb.end_date_active, xih.cutoff_date)
            AND    icmb.item_id = xxib.item_id(+)
            AND    fnlv.lookup_type(+)  = cv_lookup_itm_yokigun   -- �Q�ƃ^�C�v(�e��Q)
            AND    fnlv.language(+)     = USERENV( 'LANG' )
            AND    fnlv.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
            AND    xxib.vessel_group = fnlv.lookup_code(+)
            AND    fykn.lookup_type(+)  = cv_lookup_itm_yokikubun   -- �Q�ƃ^�C�v(�e��敪)
            AND    fykn.language(+)     = USERENV( 'LANG' )
            AND    fykn.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fykn.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fykn.end_date_active(+),   gd_process_date ) )
            AND    fnlv.attribute1 = fykn.lookup_code(+)
            AND    fvdt.lookup_type(+)  = cv_lookup_vd_class_type    -- �Q�ƃ^�C�v(�ėp����VD�Ώۏ�����)
            AND    fvdt.language(+)     = USERENV( 'LANG' )
            AND    fvdt.enabled_flag(+) = 'Y'
            AND    gd_process_date BETWEEN  TRUNC( NVL( fvdt.start_date_active(+), gd_process_date ) )
                                       AND  TRUNC( NVL( fvdt.end_date_active(+),   gd_process_date ) )
            AND    xxca.business_low_type = fvdt.lookup_code(+)
            AND    EXISTS (
                     -- �����w�b�_�f�[�^�쐬�p�����[�^������ڋq�ɕR�t���[�i��ڋq�������ΏۂƂ���
                     SELECT  'X'
                     FROM    hz_cust_acct_relate    bill_hcar
                            ,(
                       SELECT  bill_hzca.account_number    bill_account_number
                              ,ship_hzca.account_number    ship_account_number
                              ,bill_hzca.cust_account_id   bill_account_id
                              ,ship_hzca.cust_account_id   ship_account_id
                       FROM    hz_cust_accounts          bill_hzca
                              ,hz_cust_acct_sites        bill_hzsa
                              ,hz_cust_site_uses         bill_hsua
                              ,hz_cust_accounts          ship_hzca
                              ,hz_cust_acct_sites        ship_hasa
                              ,hz_cust_site_uses         ship_hsua
                       WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
                       AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
                       AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
                       AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
                       AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
                       AND     ship_hzca.customer_class_code = '10'
                       AND     bill_hsua.site_use_code = 'BILL_TO'
                       AND     bill_hsua.status = 'A'
                       AND     ship_hsua.status = 'A'
                     )  ship_cust_info
                     WHERE   hzca.cust_account_id = ship_cust_info.ship_account_id
                     AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
                     AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
                     AND     bill_hcar.attribute1(+) = '1'
                     AND     bill_hcar.status(+)     = 'A'
                     AND     ship_cust_info.bill_account_number = gt_bill_acct_code
                   )
          )                inlv
-- Modify 2013.01.17 Ver1.130 End
    ;
--
    -- *** ���[�J���E���R�[�h ***
-- Modify 2009.08.03 Ver1.4 Start
  TYPE get_main_data_ttype IS TABLE OF main_data_cur%ROWTYPE 
                           INDEX BY PLS_INTEGER;    -- ���C���J�[�\���p
  lt_main_data_tab  get_main_data_ttype;            -- ���C���J�[�\���p
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
  TYPE get_main_data_manual_ttype IS TABLE OF main_data_manual_cur%ROWTYPE 
                           INDEX BY PLS_INTEGER;          -- �蓮���s���C���J�[�\���p
  lt_main_data_manual_tab  get_main_data_manual_ttype;    -- �蓮���s���C���J�[�\���p
-- Modify 2013.01.17 Ver1.130 End
--
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
-- Modify 2013.01.17 Ver1.130 Start
-- Modify 2009.08.03 Ver1.4 Start
--    lt_main_data_tab.DELETE;  -- ���C���J�[�\���p
-- Modify 2009.08.03 Ver1.4 End
    IF (gv_batch_on_judge_type = cv_judge_type_batch) THEN
      lt_main_data_tab.DELETE;  -- ���C���J�[�\���p
    ELSE
      lt_main_data_manual_tab.DELETE;  -- ���C���J�[�\���p(�蓮���s)
    END IF;
-- Modify 2013.01.17 Ver1.130 End
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --�������׏��e�[�u���o�^����
    --==============================================================
    -- �������׏��e�[�u���o�^
-- Modify 2009.08.03 Ver1.4 Start
--    BEGIN
--      INSERT INTO xxcfr_invoice_lines(
--        invoice_id,                               -- �ꊇ������ID
--        invoice_detail_num,                       -- �ꊇ����������No
--        note_line_id,                             -- �`�[����No
--        ship_cust_code,                           -- �[�i��ڋq�R�[�h
--        ship_cust_name,                           -- �[�i��ڋq��
--        ship_cust_kana_name,                      -- �[�i��ڋq�J�i��
--        sold_location_code,                       -- ���㋒�_�R�[�h
--        sold_location_name,                       -- ���㋒�_��
--        ship_shop_code,                           -- �[�i��X�܃R�[�h
--        ship_shop_name,                           -- �[�i��X��
--        vd_num,                                   -- �����̔��@�ԍ�
--        vd_cust_type,                             -- VD�ڋq�敪
--        inv_type,                                 -- �����敪
--        chain_shop_code,                          -- �`�F�[���X�R�[�h
--        delivery_date,                            -- �[�i��
--        slip_num,                                 -- �`�[�ԍ�
--        order_num,                                -- �I�[�_�[NO
--        column_num,                               -- �R����No
--        slip_type,                                -- �`�[�敪
--        classify_type,                            -- ���ދ敪
--        customer_dept_code,                       -- ���q�l����R�[�h
--        customer_division_code,                   -- ���q�l�ۃR�[�h
--        sold_return_type,                         -- ����ԕi�敪
--        nichiriu_by_way_type,                     -- �j�`���E�o�R�敪
--        sale_type,                                -- �����敪
--        direct_num,                               -- ��No
--        po_date,                                  -- ������
--        acceptance_date,                          -- ������
--        item_code,                                -- ���iCD
--        item_name,                                -- ���i��
--        item_kana_name,                           -- ���i�J�i��
--        policy_group,                             -- ����Q�R�[�h
--        jan_code,                                 -- JAN�R�[�h
--        vessel_type,                              -- �e��敪
--        vessel_type_name,                         -- �e��敪��
--        vessel_group,                             -- �e��Q
--        vessel_group_name,                        -- �e��Q��
--        quantity,                                 -- ����
--        unit_price,                               -- �P��
--        dlv_qty,                                  -- �[�i����
--        dlv_unit_price,                           -- �[�i�P��
--        dlv_uom_code,                             -- �[�i�P��
--        standard_uom_code,                        -- ��P��
--        standard_unit_price_excluded,             -- �Ŕ���P��
--        business_cost,                            -- �c�ƌ���
--        tax_amount,                               -- ����ŋ��z
--        tax_rate,                                 -- ����ŗ�
--        ship_amount,                              -- �[�i���z
--        sold_amount,                              -- ������z
--        red_black_slip_type,                      -- �ԓ`���`�敪
--        trx_id,                                   -- ���ID
--        trx_number,                               -- ����ԍ�
--        cust_trx_type_id,                         -- ����^�C�vID
--        batch_source_id,                          -- ����\�[�XID
--        created_by,                               -- �쐬��
--        creation_date,                            -- �쐬��
--        last_updated_by,                          -- �ŏI�X�V��
--        last_update_date,                         -- �ŏI�X�V��
--        last_update_login ,                       -- �ŏI�X�V���O�C��
--        request_id,                               -- �v��ID
--        program_application_id,                   -- �A�v���P�[�V����ID
--        program_id,                               -- �v���O����ID
--        program_update_date                       -- �v���O�����X�V��
--    ) 
--      SELECT inlv.invoice_id                   invoice_id,                    -- �ꊇ������ID
--             ROWNUM                            invoice_detail_num,            -- �ꊇ����������No
--             inlv.note_line_id                 note_line_id,                  -- �`�[����No
--             inlv.ship_cust_code               ship_cust_code,                -- �[�i��ڋq�R�[�h
---- Modify 2009.07.22 Ver1.3 Start
----             inlv.ship_cust_name               ship_cust_name,                -- �[�i��ڋq��
----             inlv.ship_cust_kana_name          ship_cust_kana_name,           -- �[�i��ڋq�J�i��
--             ship.party_name                   ship_cust_name,                -- �[�i��ڋq��
--             ship.organization_name_phonetic   ship_cust_kana_name,           -- �[�i��ڋq�J�i��
---- Modify 2009.07.22 Ver1.3 End
--             inlv.sold_location_code           sold_location_code,            -- ���㋒�_�R�[�h
---- Modify 2009.07.22 Ver1.3 Start
----             inlv.sold_location_name           sold_location_name,            -- ���㋒�_��
--             sold.party_name                   sold_location_name,            -- ���㋒�_��
---- Modify 2009.07.22 Ver1.3 End
--             inlv.ship_shop_code               ship_shop_code,                -- �[�i��X�܃R�[�h
--             inlv.ship_shop_name               ship_shop_name,                -- �[�i��X��
--             inlv.vd_num                       vd_num,                        -- �����̔��@�ԍ�
--             inlv.vd_cust_type                 vd_cust_type,                  -- VD�ڋq�敪
--             inlv.inv_type                     inv_type,                      -- �����敪
--             inlv.chain_shop_code              chain_shop_code,               -- �`�F�[���X�R�[�h
--             inlv.delivery_date                delivery_date,                 -- �[�i��
--             inlv.slip_num                     slip_num,                      -- �`�[�ԍ�
--             inlv.order_num                    order_num,                     -- �I�[�_�[NO
--             inlv.column_num                   column_num,                    -- �R����No
--             inlv.slip_type                    slip_type,                     -- �`�[�敪
--             inlv.classify_type                classify_type,                 -- ���ދ敪
--             inlv.customer_dept_code           customer_dept_code,            -- ���q�l����R�[�h
--             inlv.customer_division_code       customer_division_code,        -- ���q�l�ۃR�[�h
--             inlv.sold_return_type             sold_return_type,              -- ����ԕi�敪
--             inlv.nichiriu_by_way_type         nichiriu_by_way_type,          -- �j�`���E�o�R�敪
--             inlv.sale_type                    sale_type,                     -- �����敪
--             inlv.direct_num                   direct_num,                    -- ��No
--             inlv.po_date                      po_date,                       -- ������
--             inlv.acceptance_date              acceptance_date,               -- ������
--             inlv.item_code                    item_code,                     -- ���iCD
--             inlv.item_name                    item_name,                     -- ���i��
--             inlv.item_kana_name               item_kana_name,                -- ���i�J�i��
--             inlv.policy_group                 policy_group,                  -- ����Q�R�[�h
--             inlv.jan_code                     jan_code,                      -- JAN�R�[�h
--             inlv.vessel_type                  vessel_type,                   -- �e��敪
--             inlv.vessel_type_name             vessel_type_name,              -- �e��敪��
--             inlv.vessel_group                 vessel_group,                  -- �e��Q
--             inlv.vessel_group_name            vessel_group_name,             -- �e��Q��
--             inlv.quantity                     quantity,                      -- ����
--             inlv.unit_price                   unit_price,                    -- �P��
--             inlv.dlv_qty                      dlv_qty,                       -- �[�i����
--             inlv.dlv_unit_price               dlv_unit_price,                -- �[�i�P��
--             inlv.dlv_uom_code                 dlv_uom_code,                  -- �[�i�P��
--             inlv.standard_uom_code            standard_uom_code,             -- ��P��
--             inlv.standard_unit_price_excluded standard_unit_price_excluded,  -- �Ŕ���P��
--             inlv.business_cost                business_cost,                 -- �c�ƌ���
--             inlv.tax_amount                   tax_amount,                    -- ����ŋ��z
--             inlv.tax_rate                     tax_rate,                      -- ����ŗ�
--             inlv.ship_amount                  ship_amount,                   -- �[�i���z
--             inlv.sold_amount                  sold_amount,                   -- ������z
--             inlv.red_black_slip_type          red_black_slip_type,           -- �ԓ`���`�敪
--             inlv.trx_id                       trx_id,                        -- ���ID
--             inlv.trx_number                   trx_number,                    -- ����ԍ�
--             inlv.cust_trx_type_id             cust_trx_type_id,              -- ����^�C�vID
--             inlv.batch_source_id              batch_source_id,               -- ����\�[�XID
--             inlv.created_by                   created_by,                    -- �쐬��
--             inlv.creation_date                creation_date,                 -- �쐬��
--             inlv.last_updated_by              last_updated_by,               -- �ŏI�X�V��
--             inlv.last_update_date             last_update_date,              -- �ŏI�X�V��
--             inlv.last_update_login            last_update_login ,            -- �ŏI�X�V���O�C��
--             inlv.request_id                   request_id,                    -- �v��ID
--             inlv.program_application_id       program_application_id,        -- �A�v���P�[�V����ID
--             inlv.program_id                   program_id,                    -- �v���O����ID
--             inlv.program_update_date          program_update_date            -- �v���O�����X�V��
--      FROM  (
--        --�������׃f�[�^(AR�������) 
---- Modify 2009.07.22 Ver1.3 Start
----        SELECT in_invoice_id                                  invoice_id,             -- �ꊇ������ID
--        SELECT xih.invoice_id                                 invoice_id,             -- �ꊇ������ID
---- Modify 2009.07.22 Ver1.3 End
--               NULL                                           note_line_id,           -- �`�[����No
--               hzca.account_number                            ship_cust_code,         -- �[�i��ڋq�R�[�h
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_f)                          ship_cust_name,         -- �[�i��ڋq��
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_k)                          ship_cust_kana_name,    -- �[�i��ڋq�J�i��
--               hzca.party_id                                  ship_party_id,
---- Modify 2009.07.22 Ver1.3 End
--               xxca.sale_base_code                            sold_location_code,     -- ���㋒�_�R�[�h
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 xxca.sale_base_code,
----                 cv_get_acct_name_f)                          sold_location_name,     -- ���㋒�_��
---- Modify 2009.07.22 Ver1.3 End
--               xxca.store_code                                ship_shop_code,         -- �[�i��X�܃R�[�h
--               xxca.cust_store_name                           ship_shop_name,         -- �[�i��X��
--               xxca.vendor_machine_number                     vd_num,                 -- �����̔��@�ԍ�
--               NVL(fnvd.attribute1, '0')                      vd_cust_type,           -- VD�ڋq�敪
--               DECODE(rcta.attribute7,
--                        cv_inv_hold_status_r, cv_inv_type_re
--                                            , cv_inv_type_no) inv_type,               -- �����敪
--               xxca.chain_store_code                          chain_shop_code,        -- �`�F�[���X�R�[�h
--               rgda.gl_date                                   delivery_date,          -- �[�i��
--               rlli.interface_line_attribute3                 slip_num,               -- �`�[�ԍ�
--               NULL                                           order_num,              -- �I�[�_�[NO
--               NULL                                           column_num,             -- �R����No
--               NULL                                           slip_type,              -- �`�[�敪
--               NULL                                           classify_type,          -- ���ދ敪
--               NULL                                           customer_dept_code,     -- ���q�l����R�[�h
--               NULL                                           customer_division_code, -- ���q�l�ۃR�[�h
--               NULL                                           sold_return_type,       -- ����ԕi�敪
--               NULL                                           nichiriu_by_way_type,   -- �j�`���E�o�R�敪
--               NULL                                           sale_type,              -- �����敪
--               NULL                                           direct_num,             -- ��No
--               NULL                                           po_date,                -- ������
--               rcta.trx_date                                  acceptance_date,        -- ������
--               NULL                                           item_code,              -- ���iCD
--               NULL                                           item_name,              -- ���i��
--               NULL                                           item_kana_name,         -- ���i�J�i��
--               NULL                                           policy_group,           -- ����Q�R�[�h
--               NULL                                           jan_code,               -- JAN�R�[�h
--               NULL                                           vessel_type,            -- �e��敪
--               NULL                                           vessel_type_name,       -- �e��敪��
--               NULL                                           vessel_group,           -- �e��Q
--               NULL                                           vessel_group_name,      -- �e��Q��
--               rlli.quantity_invoiced                         quantity,               -- ����
--               rlli.unit_selling_price                        unit_price,             -- �P��
--               rlli.quantity_invoiced                         dlv_qty,                      -- �[�i����
--               rlli.unit_selling_price                        dlv_unit_price,               -- �[�i�P��
--               NULL                                           dlv_uom_code,                 -- �[�i�P��
--               NULL                                           standard_uom_code,            -- ��P��
--               NULL                                           standard_unit_price_excluded, -- �Ŕ���P��
--               NULL                                           business_cost,                -- �c�ƌ���
--               rlta.extended_amount                           tax_amount,             -- ����ŋ��z
--               arta.tax_rate                                  tax_rate,               -- ����ŗ�
--               rlli.extended_amount                           ship_amount,            -- �[�i���z
---- Modify 2009.07.22 Ver1.3 Start
----               DECODE(iv_tax_type,
--               DECODE(xih.tax_type,
---- Modify 2009.07.22 Ver1.3 End
--                        cv_tax_div_outtax,   rlli.extended_amount,    -- �O�Ł@�F�Ŕ��z
--                        cv_tax_div_notax,    rlli.extended_amount,    -- ��ېŁF�Ŕ��z
--                        cv_tax_div_inslip,   rlli.extended_amount,    -- ����(�`�[)�F�Ŕ��z
--                        rlli.extended_amount + rlta.extended_amount)  -- ����(�P��)�F�ō��z
--                                                              sold_amount,            -- ������z
--               NULL                                           red_black_slip_type,    -- �ԓ`���`�敪
--               rcta.customer_trx_id                           trx_id,                 -- ���ID
--               rcta.trx_number                                trx_number,             -- ����ԍ�
--               rcta.cust_trx_type_id                          cust_trx_type_id,       -- ����^�C�vID
--               rcta.batch_source_id                           batch_source_id,        -- ����\�[�XID
--               cn_created_by                                  created_by,             -- �쐬��
--               cd_creation_date                               creation_date,          -- �쐬��
--               cn_last_updated_by                             last_updated_by,        -- �ŏI�X�V��
--               cd_last_update_date                            last_update_date,       -- �ŏI�X�V��
--               cn_last_update_login                           last_update_login ,     -- �ŏI�X�V���O�C��
--               cn_request_id                                  request_id,             -- �v��ID
--               cn_program_application_id                      program_application_id, -- �A�v���P�[�V����ID
--               cn_program_id                                  program_id,             -- �v���O����ID
--               cd_program_update_date                         program_update_date     -- �v���O�����X�V��
--        FROM   
---- Modify 2009.07.22 Ver1.3 Start
--               xxcfr_invoice_headers         xih,               -- �A�h�I���������w�b�_
----               ra_customer_trx_all           rcta,              -- ����e�[�u��
--               ra_customer_trx               rcta,              -- ����e�[�u��
---- Modify 2009.07.22 Ver1.3 End
--               hz_cust_accounts              hzca,              -- �ڋq�}�X�^
--               xxcmm_cust_accounts           xxca,              -- �ڋq�ǉ����
---- Modify 2009.07.22 Ver1.3 Start
----               hz_cust_acct_sites_all        hzsa,              -- �ڋq���ݒn
----               ra_customer_trx_lines_all     rlli,              -- �������(����)�e�[�u��
----               ra_customer_trx_lines_all     rlta,              -- �������(�Ŋz)�e�[�u��
----               ra_cust_trx_line_gl_dist_all  rgda,              -- �����v���e�[�u��
--               hz_cust_acct_sites            hzsa,              -- �ڋq���ݒn
--               ra_customer_trx_lines         rlli,              -- �������(����)�e�[�u��
--               ra_customer_trx_lines         rlta,              -- �������(�Ŋz)�e�[�u��
--               ra_cust_trx_line_gl_dist      rgda,              -- �����v���e�[�u��
---- Modify 2009.07.22 Ver1.3 End
--               ar_vat_tax_all_b              arta,              -- �ŋ��}�X�^
--               fnd_lookup_values             fnvd               -- �N�C�b�N�R�[�h(VD�ڋq�敪)
---- Modify 2009.07.22 Ver1.3 Start
----        WHERE  rcta.trx_date <= id_cutoff_date                  -- �����
--        WHERE  xih.request_id            = gt_target_request_id       -- �^�[�Q�b�g�ƂȂ�v��ID
--        AND    rcta.trx_date            <= xih.cutoff_date            -- �����
--        AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- ������ڋqID
--        AND    xih.org_id                = gn_org_id                      -- �g�DID
--        AND    xih.set_of_books_id       = gn_set_book_id        -- ��v����ID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                   cv_inv_hold_status_r)        -- �������ۗ��X�e�[�^�X
---- Modify 2009.07.22 Ver1.3 Start
----        AND    rcta.bill_to_customer_id = iv_cust_acct_id       -- ������ڋqID
----        AND    rcta.org_id          = gn_org_id                 -- �g�DID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.set_of_books_id = gn_set_book_id            -- ��v����ID
--        AND    rcta.batch_source_id = gt_arinput_trx_source_id  -- ����\�[�X
--        AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
--        AND    rcta.ship_to_customer_id = xxca.customer_id(+)
--        AND    hzca.cust_account_id = hzsa.cust_account_id(+)
---- Modify 2009.07.22 Ver1.3 Start
----        AND    hzsa.org_id(+) = gn_org_id
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.customer_trx_id = rlli.customer_trx_id
--        AND    rlli.customer_trx_id = rlta.customer_trx_id(+)
--        AND    rlli.customer_trx_line_id = rlta.link_to_cust_trx_line_id(+)
--        AND    rlli.line_type = cv_line_type_line
--        AND    rlta.line_type(+) = cv_line_type_tax
--        AND    rcta.customer_trx_id = rgda.customer_trx_id
--        AND    rgda.account_class = cv_account_class_rec
--        AND    rlta.vat_tax_id = arta.vat_tax_id
--        AND    fnvd.lookup_type(+)  = cv_lookup_vd_class_type    -- �Q�ƃ^�C�v(�ėp����VD�Ώۏ�����)
--        AND    fnvd.language(+)     = USERENV( 'LANG' )
--        AND    fnvd.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fnvd.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fnvd.end_date_active(+),   gd_process_date ) )
--        AND    xxca.business_low_type = fnvd.lookup_code(+)
--        UNION ALL
--        --�������׃f�[�^(�̔�����) 
---- Modify 2009.07.22 Ver1.3 Start
----        SELECT in_invoice_id                                   invoice_id,             -- �ꊇ������ID
--        SELECT xih.invoice_id                                  invoice_id,             -- �ꊇ������ID
---- Modify 2009.07.22 Ver1.3 End
--               xxel.dlv_invoice_line_number                    note_line_id,            -- �`�[����No
--               hzca.account_number                             ship_cust_code,          -- �[�i��ڋq�R�[�h
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_f)                           ship_cust_name,          -- �[�i��ڋq��
----               xxcfr_common_pkg.get_cust_account_name(
----                 hzca.account_number,
----                 cv_get_acct_name_k)                           ship_cust_kana_name,     -- �[�i��ڋq�J�i��
--               hzca.party_id                                   ship_party_id,
---- Modify 2009.07.22 Ver1.3 End
--               xxca.sale_base_code                             sold_location_code,      -- ���㋒�_�R�[�h
---- Modify 2009.07.22 Ver1.3 Start
----               xxcfr_common_pkg.get_cust_account_name(
----                 xxca.sale_base_code,
----                 cv_get_acct_name_f)                           sold_location_name,      -- ���㋒�_��
---- Modify 2009.07.22 Ver1.3 End
--               xxca.store_code                                 ship_shop_code,          -- �[�i��X�܃R�[�h
--               xxca.cust_store_name                            ship_shop_name,          -- �[�i��X��
--               xxca.vendor_machine_number                      vd_num,                  -- �����̔��@�ԍ�
--               NVL(fvdt.attribute1, '0')                       vd_cust_type,            -- VD�ڋq�敪
--               DECODE(rcta.attribute7,
--                        cv_inv_hold_status_r, cv_inv_type_re
--                                            , cv_inv_type_no)  inv_type,                -- �����敪
--               xxca.chain_store_code                           chain_shop_code,         -- �`�F�[���X�R�[�h
--               xxeh.delivery_date                              delivery_date,           -- �[�i��
--               xxeh.dlv_invoice_number                         slip_num,                -- �`�[�ԍ�
--               xxeh.order_invoice_number                       order_num,               -- �I�[�_�[NO
--               xxel.column_no                                  column_num,              -- �R����No
--               xxeh.invoice_class                              slip_type,               -- �`�[�敪
--               xxeh.invoice_classification_code                classify_type,           -- ���ދ敪
--               xedh.other_party_department_code                customer_dept_code,      -- ���q�l����R�[�h
--               xedh.delivery_to_section_code                   customer_division_code,  -- ���q�l�ۃR�[�h
--               fdsc.attribute1                                 sold_return_type,        -- ����ԕi�敪
--               NULL                                            nichiriu_by_way_type,    -- �j�`���E�o�R�敪
--               fscl.attribute8                                 sale_type,               -- �����敪
--               xedh.opportunity_no                             direct_num,              -- ��No
--               xedh.order_date                                 po_date,                 -- ������
--               rcta.trx_date                                   acceptance_date,         -- ������
--               xxel.item_code                                  item_code,               -- ���iCD
--               mtib.description                                item_name,               -- ���i��
--               xxmb.item_name_alt                              item_kana_name,          -- ���i�J�i��
--               icmb.attribute2                                 policy_group,            -- ����Q�R�[�h
--               icmb.attribute21                                jan_code,                -- JAN�R�[�h
--               fnlv.attribute1                                 vessel_type,             -- �e��敪
--               fykn.meaning                                    vessel_type_name,        -- �e��敪��
--               xxib.vessel_group                               vessel_group,            -- �e��Q
--               fnlv.meaning                                    vessel_group_name,       -- �e��Q��
--               xxel.standard_qty                               quantity,                -- ����(�����)
--               xxel.standard_unit_price                        unit_price,              -- �P��(��P��)
--               xxel.dlv_qty                                    dlv_qty,                 -- �[�i����
--               xxel.dlv_unit_price                             dlv_unit_price,               -- �[�i�P��
--               xxel.dlv_uom_code                               dlv_uom_code,                 -- �[�i�P��
--               xxel.standard_uom_code                          standard_uom_code,            -- ��P��
--               xxel.standard_unit_price_excluded               standard_unit_price_excluded, -- �Ŕ���P��
--               xxel.business_cost                              business_cost,                -- �c�ƌ���
--               xxel.tax_amount                                 tax_amount,              -- ����ŋ��z
--               xxeh.tax_rate                                   tax_rate,                -- ����ŗ�
--               xxel.pure_amount                                ship_amount,             -- �[�i���z
--               xxel.sale_amount                                sold_amount,             -- ������z
--               NULL                                            red_black_slip_type,     -- �ԓ`���`�敪
--               rcta.customer_trx_id                            trx_id,                  -- ���ID
--               rcta.trx_number                                 trx_number,              -- ����ԍ�
--               rcta.cust_trx_type_id                           cust_trx_type_id,        -- ����^�C�vID
--               rcta.batch_source_id                            batch_source_id,         -- ����\�[�XID
--               cn_created_by                                   created_by,              -- �쐬��
--               cd_creation_date                                creation_date,           -- �쐬��
--               cn_last_updated_by                              last_updated_by,         -- �ŏI�X�V��
--               cd_last_update_date                             last_update_date,        -- �ŏI�X�V��
--               cn_last_update_login                            last_update_login ,      -- �ŏI�X�V���O�C��
--               cn_request_id                                   request_id,              -- �v��ID
--               cn_program_application_id                       program_application_id,  -- �A�v���P�[�V����ID
--               cn_program_id                                   program_id,              -- �v���O����ID
--               cd_program_update_date                          program_update_date      -- �v���O�����X�V��
--        FROM   
---- Modify 2009.07.22 Ver1.3 Start
--               xxcfr_invoice_headers         xih,               -- �A�h�I���������w�b�_
----               ra_customer_trx_all           rcta,           -- ����e�[�u��
--               ra_customer_trx               rcta,           -- ����e�[�u��
---- Modify 2009.07.22 Ver1.3 End
--               hz_cust_accounts              hzca,           -- �ڋq�}�X�^
--               xxcmm_cust_accounts           xxca,           -- �ڋq�ǉ����
---- Modify 2009.07.22 Ver1.3 Start
----               hz_cust_acct_sites_all        hzsa,           -- �ڋq���ݒn
----               ra_customer_trx_lines_all     rlli,           -- ������׃e�[�u��
--               hz_cust_acct_sites            hzsa,           -- �ڋq���ݒn
--               ra_customer_trx_lines         rlli,           -- ������׃e�[�u��
---- Modify 2009.07.22 Ver1.3 End
--               xxcos_sales_exp_headers       xxeh,           -- �̔����уw�b�_�e�[�u��
--               xxcos_sales_exp_lines         xxel,           -- �̔����і��׃e�[�u��
--               xxcos_edi_headers             xedh,           -- EDI�w�b�_���e�[�u��
--               mtl_system_items_b            mtib,           -- �i�ڃ}�X�^
--               xxcmm_system_items_b          xxib,           -- Disc�i�ڃA�h�I��
--               fnd_lookup_values             fnlv,           -- �N�C�b�N�R�[�h(�e��Q)
--               fnd_lookup_values             fykn,           -- �N�C�b�N�R�[�h(�e��敪)
--               fnd_lookup_values             fdsc,           -- �N�C�b�N�R�[�h(�[�i�`�[�敪)
--               fnd_lookup_values             fscl,           -- �N�C�b�N�R�[�h(����敪)
--               fnd_lookup_values             fvdt,           -- �N�C�b�N�R�[�h(VD�ڋq�敪)
--               ic_item_mst_b                 icmb,           -- OPM�i�ڃ}�X�^
--               xxcmn_item_mst_b              xxmb            -- OPM�i�ڃA�h�I��
---- Modify 2009.07.22 Ver1.3 Start
----        WHERE  rcta.trx_date <= id_cutoff_date                  -- �����
--        WHERE  xih.request_id            = gt_target_request_id       -- �^�[�Q�b�g�ƂȂ�v��ID
--        AND    rcta.trx_date            <= xih.cutoff_date            -- �����
--        AND    rcta.bill_to_customer_id  = xih.bill_cust_account_id   -- ������ڋqID
--        AND    xih.org_id                = gn_org_id                      -- �g�DID
--        AND    xih.set_of_books_id       = gn_set_book_id        -- ��v����ID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                   cv_inv_hold_status_r)         -- �������ۗ��X�e�[�^�X
---- Modify 2009.07.22 Ver1.3 Start
----        AND    rcta.bill_to_customer_id = iv_cust_acct_id        -- ������ڋqID
----        AND    rcta.org_id          = gn_org_id                  -- �g�DID
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.set_of_books_id = gn_set_book_id             -- ��v����ID
--        AND    rcta.batch_source_id != gt_arinput_trx_source_id  -- ����\�[�X(AR������͈ȊO)
--        AND    rcta.ship_to_customer_id = hzca.cust_account_id(+)
--        AND    rcta.ship_to_customer_id = xxca.customer_id(+)
--        AND    hzca.cust_account_id = hzsa.cust_account_id(+)
---- Modify 2009.07.22 Ver1.3 Start
----        AND    hzsa.org_id(+) = gn_org_id
---- Modify 2009.07.22 Ver1.3 End
--        AND    rcta.customer_trx_id = rlli.customer_trx_id
--        AND    rlli.line_type = cv_line_type_line
--        AND    rlli.interface_line_attribute7 = xxeh.sales_exp_header_id  -- �̔����уw�b�_����ID
--        AND    xxeh.sales_exp_header_id = xxel.sales_exp_header_id
--        AND    xxeh.order_connection_number = xedh.order_connection_number(+)
--        AND    xxel.item_code = mtib.segment1(+)
--        AND    mtib.organization_id(+) = gt_mtl_organization_id  -- �i�ڃ}�X�^�g�DID
--        AND    fdsc.lookup_type(+)  = cv_lookup_slip_class    -- �Q�ƃ^�C�v(�[�i�`�[�敪)
--        AND    fdsc.language(+)     = USERENV( 'LANG' )
--        AND    fdsc.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fdsc.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fdsc.end_date_active(+),   gd_process_date ) )
--        AND    xxeh.dlv_invoice_class = fdsc.lookup_code(+)
--        AND    fscl.lookup_type(+)  = cv_lookup_sale_class    -- �Q�ƃ^�C�v(����敪)
--        AND    fscl.language(+)     = USERENV( 'LANG' )
--        AND    fscl.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fscl.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fscl.end_date_active(+),   gd_process_date ) )
--        AND    xxel.sales_class = fscl.lookup_code(+)
--        AND    mtib.segment1 = icmb.item_no(+)
--        AND    icmb.item_id  = xxmb.item_id(+)
--        AND    xxmb.active_flag(+) = 'Y'
---- Modify 2009.07.22 Ver1.3 Start
----        AND    id_cutoff_date >= TRUNC(xxmb.start_date_active(+))
----        AND    id_cutoff_date <= NVL(xxmb.end_date_active(+), id_cutoff_date)
--        AND    xih.cutoff_date >= NVL(TRUNC(xxmb.start_date_active), xih.cutoff_date)
--        AND    xih.cutoff_date <= NVL(xxmb.end_date_active, xih.cutoff_date)
---- Modify 2009.07.22 Ver1.3 End
--        AND    icmb.item_id = xxib.item_id(+)
--        AND    fnlv.lookup_type(+)  = cv_lookup_itm_yokigun   -- �Q�ƃ^�C�v(�e��Q)
--        AND    fnlv.language(+)     = USERENV( 'LANG' )
--        AND    fnlv.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fnlv.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fnlv.end_date_active(+),   gd_process_date ) )
--        AND    xxib.vessel_group = fnlv.lookup_code(+)
--        AND    fykn.lookup_type(+)  = cv_lookup_itm_yokikubun   -- �Q�ƃ^�C�v(�e��敪)
--        AND    fykn.language(+)     = USERENV( 'LANG' )
--        AND    fykn.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fykn.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fykn.end_date_active(+),   gd_process_date ) )
--        AND    fnlv.attribute1 = fykn.lookup_code(+)
--        AND    fvdt.lookup_type(+)  = cv_lookup_vd_class_type    -- �Q�ƃ^�C�v(�ėp����VD�Ώۏ�����)
--        AND    fvdt.language(+)     = USERENV( 'LANG' )
--        AND    fvdt.enabled_flag(+) = 'Y'
--        AND    gd_process_date BETWEEN  TRUNC( NVL( fvdt.start_date_active(+), gd_process_date ) )
--                                   AND  TRUNC( NVL( fvdt.end_date_active(+),   gd_process_date ) )
--        AND    xxca.business_low_type = fvdt.lookup_code(+)
--        
--      )  inlv
---- Modify 2009.07.22 Ver1.3 Start
--     ,hz_parties       ship    -- 
--     ,hz_parties       sold    -- 
--     ,hz_cust_accounts soldca  -- 
--    WHERE inlv.ship_party_id      = ship.party_id
--      AND inlv.sold_location_code = soldca.account_number
--      AND soldca.party_id         = sold.party_id
---- Modify 2009.07.22 Ver1.3 End
--    ;
----
--    --�������׃f�[�^�o�^�����J�E���g
--    gn_target_line_cnt := gn_target_line_cnt + SQL%ROWCOUNT;
----
--    EXCEPTION
--    -- *** OTHERS��O�n���h�� ***
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
--                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
--                                                      -- �������׏��e�[�u��
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
--
-- Modify 2013.01.17 Ver1.130 Start
    --��Ԏ蓮���f�敪�̔��f(��ԃW���u�Ǝ蓮���s�ŕ���)
    IF (gv_batch_on_judge_type = cv_judge_type_batch) THEN
-- Modify 2013.01.17 Ver1.130 End
    OPEN main_data_cur;
--
    <<main_loop>>
    LOOP
--
      -- �Ώۃf�[�^���ꊇ�擾(���~�b�g�P��)
      FETCH main_data_cur BULK COLLECT INTO lt_main_data_tab LIMIT gn_bulk_limit;
--
      -- �Ώۃf�[�^���Ȃ��Ȃ�����I��
      EXIT WHEN lt_main_data_tab.COUNT < 1;
--
      BEGIN
--
        -- �Ώۃf�[�^���ꊇ�o�^(���~�b�g�P��)
        FORALL ln_loop_cnt IN lt_main_data_tab.FIRST..lt_main_data_tab.LAST
--
          INSERT INTO xxcfr_invoice_lines
          VALUES      lt_main_data_tab(ln_loop_cnt)
         ;
--
      --�������׃f�[�^�o�^�����J�E���g
      gn_target_line_cnt := gn_target_line_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
      -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                        -- �������׏��e�[�u��
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- �ϐ���������
      lt_main_data_tab.DELETE;
--
    END LOOP main_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE main_data_cur;
--
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
    --�蓮���s�p
    ELSE
--
    OPEN main_data_manual_cur;
--
    <<main_manual_loop>>
    LOOP
--
      -- �Ώۃf�[�^���ꊇ�擾(���~�b�g�P��)
      FETCH main_data_manual_cur BULK COLLECT INTO lt_main_data_manual_tab LIMIT gn_bulk_limit;
--
      -- �Ώۃf�[�^���Ȃ��Ȃ�����I��
      EXIT WHEN lt_main_data_manual_tab.COUNT < 1;
--
      BEGIN
--
        -- �Ώۃf�[�^���ꊇ�o�^(���~�b�g�P��)
        FORALL ln_loop_cnt IN lt_main_data_manual_tab.FIRST..lt_main_data_manual_tab.LAST
--
          INSERT INTO xxcfr_invoice_lines
          VALUES      lt_main_data_manual_tab(ln_loop_cnt)
         ;
--
      --�������׃f�[�^�o�^�����J�E���g
      gn_target_line_cnt := gn_target_line_cnt + SQL%ROWCOUNT;
--
      EXCEPTION
      -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
                                                        -- �������׏��e�[�u��
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- �ϐ���������
      lt_main_data_manual_tab.DELETE;
--
    END LOOP main_manual_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE main_data_manual_cur;
--
    END IF;
-- Modify 2013.01.17 Ver1.130 End
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( main_data_cur%ISOPEN ) THEN
        CLOSE main_data_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( main_data_manual_cur%ISOPEN ) THEN
        CLOSE main_data_manual_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_inv_detail_data;
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : ins_aroif_data
--   * Description      : AR���OIF�o�^����(A-4)
--   ***********************************************************************************/
--  PROCEDURE ins_aroif_data(
--    in_invoice_id           IN  NUMBER,       -- �ꊇ������ID
--    in_tax_gap_amt          IN  NUMBER,       -- �ō��z
--    iv_term_name            IN  VARCHAR2,     -- �x��������
--    in_term_id              IN  NUMBER,       -- �x������ID
--    in_cust_acct_id         IN  NUMBER,       -- ������ڋqID
--    in_cust_site_id         IN  NUMBER,       -- ������ڋq���ݒnID
--    iv_bill_loc_code        IN  VARCHAR2,     -- �������_�R�[�h
--    iv_rec_loc_code         IN  VARCHAR2,     -- �������_�R�[�h
--    id_cutoff_date          IN  DATE,         -- ����
--    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  )
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_aroif_data'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_target_cnt       NUMBER;         -- �Ώی���
--    ln_tab_num          NUMBER;
--    ln_line_oif_cnt     NUMBER;
--    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--    lt_aroif_seq        ra_interface_lines_all.interface_line_attribute1%TYPE;  -- AR���OIF�o�^�p�V�[�P���X
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- �ō��z�f�[�^���o�J�[�\��
--    CURSOR get_tax_gap_info_cur
--    IS
--      SELECT xxgt.bill_cust_name            bill_cust_name,           -- ������ڋq��
--             xxgt.tax_code                  tax_code,                 -- �ŃR�[�h
--             xxgt.tax_code_id               tax_code_id,              -- �ŋ��R�[�hID
--             xxgt.segment3                  segment3,                 -- ����Ȗ�
--             xxgt.segment4                  segment4,                 -- �⏕�Ȗ�
--             xxgt.tax_gap_amount            tax_gap_amount,           -- �ō��z
--             xxgt.note                      note,                     -- ����
--             arta.tax_account_id            tax_ccid,                 -- �ŃR�[�hCCID
--             glcc.segment1                  tax_segment1,             -- �ŃR�[�hAFF(segment1)
--             glcc.segment2                  tax_segment2,             -- �ŃR�[�hAFF(segment2)
--             glcc.segment3                  tax_segment3,             -- �ŃR�[�hAFF(segment3)
--             glcc.segment4                  tax_segment4,             -- �ŃR�[�hAFF(segment4)
--             glcc.segment5                  tax_segment5,             -- �ŃR�[�hAFF(segment5)
--             glcc.segment6                  tax_segment6,             -- �ŃR�[�hAFF(segment6)
--             glcc.segment7                  tax_segment7,             -- �ŃR�[�hAFF(segment7)
--             glcc.segment8                  tax_segment8,             -- �ŃR�[�hAFF(segment8)
--             arta.amount_includes_tax_flag  amount_includes_tax_flag  -- ���Ńt���O
--      FROM   xxcfr_tax_gap_trx_list xxgt,
--             ar_vat_tax_all_b       arta,
--             gl_code_combinations   glcc
--      WHERE  xxgt.invoice_id = in_invoice_id
--      AND    arta.tax_code(+) = xxgt.tax_code
--      AND    gd_process_date BETWEEN arta.start_date(+)
--                                 AND NVL(arta.end_date(+), gd_process_date)
--      AND    arta.enabled_flag(+) = cv_enabled_flag_y
--      AND    arta.org_id(+) = gn_org_id
--      AND    arta.set_of_books_id(+) = gn_set_book_id
--      AND    arta.tax_account_id = glcc.code_combination_id(+)
--      ;
----
--    TYPE get_cust_name_ttype     IS TABLE OF xxcfr_tax_gap_trx_list.bill_cust_name%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_code_ttype      IS TABLE OF xxcfr_tax_gap_trx_list.tax_code%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_code_id_ttype   IS TABLE OF xxcfr_tax_gap_trx_list.tax_code_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_segment3_ttype      IS TABLE OF xxcfr_tax_gap_trx_list.segment3%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_segment4_ttype      IS TABLE OF xxcfr_tax_gap_trx_list.segment4%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_gap_amt_ttype   IS TABLE OF xxcfr_tax_gap_trx_list.tax_gap_amount%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_note_ttype          IS TABLE OF xxcfr_tax_gap_trx_list.note%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_ccid_ttype      IS TABLE OF ar_vat_tax_all_b.tax_account_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment1_ttype  IS TABLE OF gl_code_combinations.segment1%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment2_ttype  IS TABLE OF gl_code_combinations.segment2%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment3_ttype  IS TABLE OF gl_code_combinations.segment3%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment4_ttype  IS TABLE OF gl_code_combinations.segment4%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment5_ttype  IS TABLE OF gl_code_combinations.segment5%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment6_ttype  IS TABLE OF gl_code_combinations.segment6%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment7_ttype  IS TABLE OF gl_code_combinations.segment7%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_tax_segment8_ttype  IS TABLE OF gl_code_combinations.segment8%TYPE
--                                             INDEX BY PLS_INTEGER;
--    TYPE get_incl_tax_flag_ttype IS TABLE OF ar_vat_tax_all_b.amount_includes_tax_flag%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_get_cust_name_tab         get_cust_name_ttype;
--    lt_get_tax_code_tab          get_tax_code_ttype;
--    lt_get_tax_code_id_tab       get_tax_code_id_ttype;
--    lt_get_segment3_tab          get_segment3_ttype;
--    lt_get_segment4_tab          get_segment4_ttype;
--    lt_get_tax_gap_amt_tab       get_tax_gap_amt_ttype;
--    lt_get_note_tab              get_note_ttype;
--    lt_get_tax_ccid_tab          get_tax_ccid_ttype;
--    lt_get_tax_segment1_tab      get_tax_segment1_ttype;
--    lt_get_tax_segment2_tab      get_tax_segment2_ttype;
--    lt_get_tax_segment3_tab      get_tax_segment3_ttype;
--    lt_get_tax_segment4_tab      get_tax_segment4_ttype;
--    lt_get_tax_segment5_tab      get_tax_segment5_ttype;
--    lt_get_tax_segment6_tab      get_tax_segment6_ttype;
--    lt_get_tax_segment7_tab      get_tax_segment7_ttype;
--    lt_get_tax_segment8_tab      get_tax_segment8_ttype;
--    lt_get_incl_tax_flag         get_incl_tax_flag_ttype;
----
--    -- *** ���[�J���E���R�[�h ***
----
--    -- *** ���[�J����O ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ���[�J���ϐ��̏�����
--    ln_target_cnt     := 0;
--    ln_line_oif_cnt   := 1;
----
--    --==============================================================
--    --�ō��z�f�[�^���o����
--    --==============================================================
--    -- �ō��z�f�[�^���o�J�[�\���I�[�v��
--    OPEN get_tax_gap_info_cur;
----
--    -- �f�[�^�̈ꊇ�擾
--    FETCH get_tax_gap_info_cur 
--    BULK COLLECT INTO  lt_get_cust_name_tab   ,
--                       lt_get_tax_code_tab    ,
--                       lt_get_tax_code_id_tab ,
--                       lt_get_segment3_tab    ,
--                       lt_get_segment4_tab    ,
--                       lt_get_tax_gap_amt_tab ,
--                       lt_get_note_tab        ,
--                       lt_get_tax_ccid_tab    ,
--                       lt_get_tax_segment1_tab,
--                       lt_get_tax_segment2_tab,
--                       lt_get_tax_segment3_tab,
--                       lt_get_tax_segment4_tab,
--                       lt_get_tax_segment5_tab,
--                       lt_get_tax_segment6_tab,
--                       lt_get_tax_segment7_tab,
--                       lt_get_tax_segment8_tab,
--                       lt_get_incl_tax_flag
--    ;
----
--    -- ���������̃Z�b�g
--    ln_target_cnt := lt_get_cust_name_tab.COUNT;
--    -- �J�[�\���N���[�Y
--    CLOSE get_tax_gap_info_cur;
----
--    --==============================================================
--    --�V�[�P���X����A�Ԃ��擾����
--    --==============================================================
--    -- �Ώۃf�[�^�����ݎ�
--    IF (ln_target_cnt > 0) THEN
--      BEGIN
--        --AR���OIF�o�^�p�V�[�P���X����A�Ԏ擾
--        SELECT  TO_CHAR(xxcfr_ar_trx_interface_s1.NEXTVAL)  aroif_seq
--        INTO    lt_aroif_seq
--        FROM    DUAL
--        ;
----
--      EXCEPTION
--        -- *** OTHERS��O�n���h�� ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303004);    -- AR���OIF�o�^�p�V�[�P���X
--          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr,
--                                 iv_name         => cv_msg_cfr_00015,  
--                                 iv_token_name1  => cv_tkn_data,  
--                                 iv_token_value1 => lt_look_dict_word),
--                               1,
--                               5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
----
--      <<tax_gap_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
----
--        --==============================================================
--        --AR���OIF�o�^����(LINE�s)
--        --==============================================================
--        --AR���OIF�f�[�^�o�^(LINE�s)
--        BEGIN
--          -- AR���OIF(LINE�s)
--          INSERT INTO ra_interface_lines_all(
--            interface_line_context,        -- ������׃R���e�L�X�g�l
--            interface_line_attribute1,     -- �������DFF1
--            interface_line_attribute2,     -- �������DFF2
--            batch_source_name,             -- ����\�[�X
--            set_of_books_id,               -- ��v����ID
--            line_type,                     -- ���׃^�C�v
--            currency_code,                 -- �ʉ�
--            amount,                        -- ���z
--            cust_trx_type_name,            -- ����^�C�v��
--            cust_trx_type_id,              -- ����^�C�vID
--            description,                   -- �i�ږ��דE�v
--            term_name,                     -- �x��������
--            term_id,                       -- �x������ID
--            orig_system_bill_customer_id,  -- ������ڋqID
--            orig_system_bill_address_id,   -- ������ڋq���ݒnID
--            conversion_type,               -- ���Z�^�C�v
--            conversion_rate,               -- ���Z���[�g
--            trx_date,                      -- �����
--            gl_date,                       -- GL�L����
--            quantity,                      -- ����
--            unit_selling_price,            -- �̔��P��
--            unit_standard_price,           -- �W���P��
--            tax_code,                      -- �ŋ��R�[�h
--            header_attribute_category,     -- �w�b�_�[DFF�J�e�S��(�g�DID)
--            header_attribute5,             -- �w�b�_�[DFF5(���[�U�̏�������)
--            header_attribute6,             -- �w�b�_�[DFF6(���[�U)
--            header_attribute7,             -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
--            header_attribute8,             -- �w�b�_�[DFF8(�ʐ���������X�e�[�^�X)
--            header_attribute9,             -- �w�b�_�[DFF9(�ꊇ����������X�e�[�^�X)
--            header_attribute11,            -- �w�b�_�[DFF11(�������_)
--            comments,                      -- ����
--            created_by,                    -- �쐬��
--            creation_date,                 -- �쐬��
--            last_updated_by,               -- �ŏI�X�V��
--            last_update_date,              -- �ŏI�X�V��
--            last_update_login,             -- �ŏI�X�V���O�C��
--            org_id,                        -- �c�ƒP��ID
--            amount_includes_tax_flag       -- �ō����z�t���O
--          ) VALUES (
--            gt_taxd_trx_dtl_cont,                 -- ������׃R���e�L�X�g�l
--            lt_aroif_seq,                         -- �������DFF1
--            TO_CHAR(ln_line_oif_cnt),             -- �������DFF2
--            gt_taxd_trx_source,                   -- ����\�[�X
--            gn_set_book_id,                       -- ��v����ID
--            cv_line_type_line,                    -- ���׃^�C�v
--            cv_currency_code,                     -- �ʉ�
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),  -- ���z
--            gt_taxd_trx_type,                     -- ����^�C�v��
--            gt_tax_gap_trx_type_id,               -- ����^�C�vID
--            gt_taxd_trx_memo_dtl,                 -- �i�ږ��דE�v
--            iv_term_name,                         -- �x��������
--            in_term_id,                           -- �x������ID
--            in_cust_acct_id,                      -- ������ڋqID
--            in_cust_site_id,                      -- ������ڋq���ݒnID
--            cv_conversion_type,                   -- ���Z�^�C�v
--            cn_conversion_rate,                   -- ���Z���[�g
--            id_cutoff_date,                       -- �����
--            id_cutoff_date,                       -- GL�L����
--            1,                                    -- ����
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),  -- �̔��P��
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),  -- �W���P��
--            lt_get_tax_code_tab(ln_loop_cnt),     -- �ŋ��R�[�h
--            gn_org_id,                            -- �w�b�_�[DFF�J�e�S��(�g�DID)
--            iv_bill_loc_code,                     -- �w�b�_�[DFF5(���[�U�̏�������)
--            gt_user_name,                         -- �w�b�_�[DFF6(���[�U)
--            cv_inv_hold_status_p,                 -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
--            cv_inv_hold_status_w,                 -- �w�b�_�[DFF8(�ʐ���������X�e�[�^�X)
--            cv_inv_hold_status_w,                 -- �w�b�_�[DFF9(�ꊇ����������X�e�[�^�X)
--            iv_rec_loc_code,                      -- �w�b�_�[DFF11(�������_)
--            lt_get_note_tab(ln_loop_cnt),         -- ����
--            cn_created_by,                        -- �쐬��
--            cd_creation_date,                     -- �쐬��
--            cn_last_updated_by,                   -- �ŏI�X�V��
--            cd_last_update_date,                  -- �ŏI�X�V��
--            cn_last_update_login,                 -- �ŏI�X�V���O�C��
--            gn_org_id,                            -- �c�ƒP��ID
--            lt_get_incl_tax_flag(ln_loop_cnt)     -- �ō����z�t���O
--          );
----
--        EXCEPTION
--          -- *** OTHERS��O�n���h�� ***
--          WHEN OTHERS THEN
--            lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303005);    -- AR���OIF�e�[�u��(LINE�s)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,cv_msg_cfr_00016      -- �f�[�^�}���G���[
--                                 ,cv_tkn_table          -- �g�[�N��'TABLE'
--                                 ,lt_look_dict_word)
--                               ,1
--                               ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--        --==============================================================
--        --AR�����v�z���pOIF�o�^����(REV�s)
--        --==============================================================
--        --AR�����v�z���pOIF�o�^(REV�s)
--        BEGIN
--          INSERT INTO ra_interface_distributions_all(
--            interface_line_context,                 -- ������׃R���e�L�X�g�l
--            interface_line_attribute1,              -- �������DFF1
--            interface_line_attribute2,              -- �������DFF2
--            account_class,                          -- ����Ȗڋ敪
--            amount,                                 -- ���z
--            percent,                                -- �p�[�Z���g
--            code_combination_id,                    -- ����Ȗڑg����ID
--            segment1,                               -- �Z�O�����g1
--            segment2,                               -- �Z�O�����g2
--            segment3,                               -- �Z�O�����g3
--            segment4,                               -- �Z�O�����g4
--            segment5,                               -- �Z�O�����g5
--            segment6,                               -- �Z�O�����g6
--            segment7,                               -- �Z�O�����g7
--            segment8,                               -- �Z�O�����g8
--            attribute_category,                     -- DFF�J�e�S��
--            created_by,                             -- �쐬��
--            creation_date,                          -- �쐬��
--            last_updated_by,                        -- �ŏI�X�V��
--            last_update_date,                       -- �ŏI�X�V��
--            last_update_login,                      -- �ŏI�X�V���O�C��
--            org_id                                  -- �c�ƒP��ID
--          ) VALUES (
--            gt_taxd_trx_dtl_cont,                   -- ������׃R���e�L�X�g�l
--            lt_aroif_seq,                           -- �������DFF1
--            TO_CHAR(ln_line_oif_cnt),               -- �������DFF2
--            cv_account_class_rev,                   -- ����Ȗڋ敪
--            lt_get_tax_gap_amt_tab(ln_loop_cnt),    -- ���z
--            100,                                    -- �p�[�Z���g
--            lt_get_tax_ccid_tab(ln_loop_cnt),       -- ����Ȗڑg����ID
--            lt_get_tax_segment1_tab(ln_loop_cnt),   -- �Z�O�����g1
--            lt_get_tax_segment2_tab(ln_loop_cnt),   -- �Z�O�����g2
--            lt_get_tax_segment3_tab(ln_loop_cnt),   -- �Z�O�����g3
--            lt_get_tax_segment4_tab(ln_loop_cnt),   -- �Z�O�����g4
--            lt_get_tax_segment5_tab(ln_loop_cnt),   -- �Z�O�����g5
--            lt_get_tax_segment6_tab(ln_loop_cnt),   -- �Z�O�����g6
--            lt_get_tax_segment7_tab(ln_loop_cnt),   -- �Z�O�����g7
--            lt_get_tax_segment8_tab(ln_loop_cnt),   -- �Z�O�����g8
--            gn_org_id,                              -- DFF�J�e�S��
--            cn_created_by,                          -- �쐬��
--            cd_creation_date,                       -- �쐬��
--            cn_last_updated_by,                     -- �ŏI�X�V��
--            cd_last_update_date,                    -- �ŏI�X�V��
--            cn_last_update_login,                   -- �ŏI�X�V���O�C��
--            gn_org_id                               -- �c�ƒP��ID
--          );
----
--        EXCEPTION
--          -- *** OTHERS��O�n���h�� ***
--          WHEN OTHERS THEN
--            lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303008);
--                                                              -- AR�����v�z���e�[�u��(REV�s)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
--                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                 ,iv_token_value1 => lt_look_dict_word)
--                               ,1
--                               ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--        -- AR���OIF��ӃL�[�J�E���g
--        ln_line_oif_cnt := ln_line_oif_cnt + 1;
----
--        --==============================================================
--        --AR���OIF�o�^����(TAX�s)
--        --==============================================================
--        --AR���OIF�f�[�^�o�^(TAX�s)
--        BEGIN
--          -- AR���OIF(TAX�s)
--          INSERT INTO ra_interface_lines_all(
--            interface_line_context,        -- ������׃R���e�L�X�g�l
--            interface_line_attribute1,     -- �������DFF1
--            interface_line_attribute2,     -- �������DFF2
--            batch_source_name,             -- ����\�[�X
--            set_of_books_id,               -- ��v����ID
--            line_type,                     -- ���׃^�C�v
--            description,                   -- �i�ږ��דE�v
--            currency_code,                 -- �ʉ�
--            amount,                        -- ���z
--            cust_trx_type_name,            -- ����^�C�v��
--            cust_trx_type_id,              -- ����^�C�vID
--            term_name,                     -- �x��������
--            term_id,                       -- �x������ID
--            orig_system_bill_customer_id,  -- ������ڋqID
--            orig_system_bill_address_id,   -- ������ڋq���ݒnID
--            link_to_line_context,          -- �����N�斾�׃R���e�L�X�g
--            link_to_line_attribute1,       -- �����N�斾��DFF1
--            link_to_line_attribute2,       -- �����N�斾��DFF2
--            conversion_type,               -- ���Z�^�C�v
--            conversion_rate,               -- ���Z���[�g
--            trx_date,                      -- �����
--            gl_date,                       -- GL�L����
--            unit_selling_price,            -- �̔��P��
--            unit_standard_price,           -- �W���P��
--            tax_code,                      -- �ŋ��R�[�h
--            header_attribute_category,     -- �w�b�_�[DFF�J�e�S��(�g�DID)
--            header_attribute5,             -- �w�b�_�[DFF5(���[�U�̏�������)
--            header_attribute6,             -- �w�b�_�[DFF6(���[�U)
--            header_attribute7,             -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
--            header_attribute8,             -- �w�b�_�[DFF8(�ʐ���������X�e�[�^�X)
--            header_attribute9,             -- �w�b�_�[DFF9(�ꊇ����������X�e�[�^�X)
--            header_attribute11,            -- �w�b�_�[DFF11(�������_)
--            comments,                      -- ����
--            created_by,                    -- �쐬��
--            creation_date,                 -- �쐬��
--            last_updated_by,               -- �ŏI�X�V��
--            last_update_date,              -- �ŏI�X�V��
--            last_update_login,             -- �ŏI�X�V���O�C��
--            org_id,                        -- �c�ƒP��ID
--            amount_includes_tax_flag       -- �ō����z�t���O
--          ) VALUES (
--            gt_taxd_trx_dtl_cont,                 -- ������׃R���e�L�X�g�l
--            lt_aroif_seq,                         -- �������DFF1
--            ln_line_oif_cnt,                      -- �������DFF2
--            gt_taxd_trx_source,                   -- ����\�[�X
--            gn_set_book_id,                       -- ��v����ID
--            cv_line_type_tax,                     -- ���׃^�C�v
--            gt_taxd_trx_memo_dtl,                 -- �i�ږ��דE�v
--            cv_currency_code,                     -- �ʉ�
--            0,                                    -- ���z
--            gt_taxd_trx_type,                     -- ����^�C�v��
--            gt_tax_gap_trx_type_id,               -- ����^�C�vID
--            iv_term_name,                         -- �x��������
--            in_term_id,                           -- �x������ID
--            in_cust_acct_id,                      -- ������ڋqID
--            in_cust_site_id,                      -- ������ڋq���ݒnID
--            gt_taxd_trx_dtl_cont,                 -- �����N�斾�׃R���e�L�X�g
--            lt_aroif_seq,                         -- �����N�斾��DFF1
--            TO_CHAR(ln_line_oif_cnt - 1),         -- �����N�斾��DFF2
--            cv_conversion_type,                   -- ���Z�^�C�v
--            cn_conversion_rate,                   -- ���Z���[�g
--            id_cutoff_date,                       -- �����
--            id_cutoff_date,                       -- GL�L����
--            0,                                    -- �̔��P��
--            0,                                    -- �W���P��
--            lt_get_tax_code_tab(ln_loop_cnt),     -- �ŋ��R�[�h
--            gn_org_id,                            -- �w�b�_�[DFF�J�e�S��(�g�DID)
--            iv_bill_loc_code,                     -- �w�b�_�[DFF5(���[�U�̏�������)
--            gt_user_name,                         -- �w�b�_�[DFF6(���[�U)
--            cv_inv_hold_status_p,                 -- �w�b�_�[DFF7(�������ۗ��X�e�[�^�X)
--            cv_inv_hold_status_w,                 -- �w�b�_�[DFF8(�ʐ���������X�e�[�^�X)
--            cv_inv_hold_status_w,                 -- �w�b�_�[DFF9(�ꊇ����������X�e�[�^�X)
--            iv_rec_loc_code,                      -- �w�b�_�[DFF11(�������_)
--            lt_get_note_tab(ln_loop_cnt),         -- ����
--            cn_created_by,                        -- �쐬��
--            cd_creation_date,                     -- �쐬��
--            cn_last_updated_by,                   -- �ŏI�X�V��
--            cd_last_update_date,                  -- �ŏI�X�V��
--            cn_last_update_login,                 -- �ŏI�X�V���O�C��
--            gn_org_id,                            -- �c�ƒP��ID
--            lt_get_incl_tax_flag(ln_loop_cnt)     -- �ō����z�t���O
--          );
----
--          -- AR���OIF��ӃL�[�J�E���g
--          ln_line_oif_cnt := ln_line_oif_cnt + 1;
----
--        EXCEPTION
--          -- *** OTHERS��O�n���h�� ***
--          WHEN OTHERS THEN
--            lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303006);    -- AR���OIF�e�[�u��(TAX�s)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
--                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                 ,iv_token_value1 => lt_look_dict_word)
--                               ,1
--                               ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--        END;
----
--      END LOOP tax_gap_loop;
----
--      ln_tab_num := lt_get_segment3_tab.FIRST;
----
--      --AR�����v�z���pOIF�o�^(REC�s)
--      BEGIN
--        INSERT INTO ra_interface_distributions_all(
--          interface_line_context,                 -- ������׃R���e�L�X�g�l
--          interface_line_attribute1,              -- �������DFF1
--          interface_line_attribute2,              -- �������DFF2
--          account_class,                          -- ����Ȗڋ敪
--          percent,                                -- �p�[�Z���g
--          segment1,                               -- �Z�O�����g1
--          segment2,                               -- �Z�O�����g2
--          segment3,                               -- �Z�O�����g3
--          segment4,                               -- �Z�O�����g4
--          segment5,                               -- �Z�O�����g5
--          segment6,                               -- �Z�O�����g6
--          segment7,                               -- �Z�O�����g7
--          segment8,                               -- �Z�O�����g8
--          attribute_category,                     -- DFF�J�e�S��
--          created_by,                             -- �쐬��
--          creation_date,                          -- �쐬��
--          last_updated_by,                        -- �ŏI�X�V��
--          last_update_date,                       -- �ŏI�X�V��
--          last_update_login,                      -- �ŏI�X�V���O�C��
--          org_id                                  -- �c�ƒP��ID
--        ) VALUES (
--          gt_taxd_trx_dtl_cont,                   -- ������׃R���e�L�X�g�l
--          lt_aroif_seq,                           -- �������DFF1
--          1,                                      -- �������DFF2
--          cv_account_class_rec,                   -- ����Ȗڋ敪
--          100,                                    -- �p�[�Z���g
--          gt_rec_aff_segment1,                    -- �Z�O�����g1
--          gt_rec_aff_segment2,                    -- �Z�O�����g2
--          lt_get_segment3_tab(ln_tab_num),        -- �Z�O�����g3
--          lt_get_segment4_tab(ln_tab_num),        -- �Z�O�����g4
--          gt_rec_aff_segment5,                    -- �Z�O�����g5
--          gt_rec_aff_segment6,                    -- �Z�O�����g6
--          gt_rec_aff_segment7,                    -- �Z�O�����g7
--          gt_rec_aff_segment8,                    -- �Z�O�����g8
--          gn_org_id,                              -- DFF�J�e�S��
--          cn_created_by,                          -- �쐬��
--          cd_creation_date,                       -- �쐬��
--          cn_last_updated_by,                     -- �ŏI�X�V��
--          cd_last_update_date,                    -- �ŏI�X�V��
--          cn_last_update_login,                   -- �ŏI�X�V���O�C��
--          gn_org_id                               -- �c�ƒP��ID
--        );
----
--      --�Ώی���(AR���OIF�o�^����)�J�E���g�A�b�v
--      gn_target_aroif_cnt := gn_target_aroif_cnt + 1;
----
--      EXCEPTION
--        -- *** OTHERS��O�n���h�� ***
--        WHEN OTHERS THEN
--          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303007);
--                                                            -- AR�����v�z���e�[�u��(REC�s)
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                ,iv_name         => cv_msg_cfr_00016      -- �f�[�^�}���G���[
--                                ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                ,iv_token_value1 => lt_look_dict_word)
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--      END;
----
--    END IF;
----
--  EXCEPTION
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END ins_aroif_data;
-- Modify 2009.09.29 Ver1.5 End
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : start_auto_invoice
--   * Description      : �����C���{�C�X�N������(A-6)
--   ***********************************************************************************/
--  PROCEDURE start_auto_invoice(
--    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  )
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_auto_invoice'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_target_cnt       NUMBER;           -- �Ώی���
--    ln_request_id       NUMBER;           -- �N���R���J�����g�v��ID
--    lv_conc_err_flg     VARCHAR2(1);      -- �R���J�����g�G���[�t���O
--    lb_request_status   BOOLEAN;          -- �R���J�����g�X�e�[�^�X
--    lv_rphase           VARCHAR2(255);    -- �R���J�����g�I���ҋ@OUT�p�����[�^
--    lv_dphase           VARCHAR2(255);    -- �R���J�����g�I���ҋ@OUT�p�����[�^
--    lv_rstatus          VARCHAR2(255);    -- �R���J�����g�I���ҋ@OUT�p�����[�^
--    lv_dstatus          VARCHAR2(255);    -- �R���J�����g�I���ҋ@OUT�p�����[�^
--    lv_message          VARCHAR2(32000);  -- �R���J�����g�I���ҋ@OUT�p�����[�^
--    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
----
--    -- *** ���[�J���E�J�[�\�� ***
----
--    -- �����w�b�_�f�[�^�J�[�\��
--    CURSOR get_inv_err_header_cur(
--      iv_request_id    VARCHAR2
--    )
--    IS
--      SELECT xxih.invoice_id    invoice_id
--      FROM   xxcfr_invoice_headers  xxih                  -- �����w�b�_���e�[�u��
--      WHERE  EXISTS (
--               SELECT xxil.invoice_id
--               FROM   xxcfr_invoice_lines   xxil          -- �������׏��e�[�u��
--               WHERE  xxih.invoice_id = xxil.invoice_id
--               )
--      AND    xxih.request_id = iv_request_id              -- �R���J�����g�v��ID
--      AND    xxih.org_id = gn_org_id                      -- �g�DID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- ��v����ID
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE get_del_invoice_id_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_del_invoice_id_tab            get_del_invoice_id_ttype;
----
--    -- *** ���[�J���E���R�[�h ***
----
--    -- *** ���[�J����O ***
--    auto_inv_expt       EXCEPTION;      -- �����C���{�C�X�N���G���[
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ���[�J���ϐ��̏�����
--    ln_target_cnt     := 0;
--    lv_conc_err_flg   := 'N';
----
--    --==============================================================
--    --�����C���{�C�X�N������
--    --==============================================================
--    -- �R���J�����g�N��
--    ln_request_id := fnd_request.submit_request(
--                       application => cv_auto_inv_appl_name,     -- �A�v���P�[�V����
--                       program     => cv_auto_inv_prg_name,      -- �v���O����
--                       description => NULL,                      -- �E�v
--                       start_time  => NULL,                      -- �J�n����
--                       sub_request => FALSE,                     -- �T�u�v��ID
--                       argument1   => 1,                         -- ������
--                       argument2   => gt_tax_gap_trx_source_id,  -- �ō��z�v����\�[�XID
--                       argument3   => gt_taxd_trx_source,        -- �ō��z�v����\�[�X��
--                       argument4   => gd_process_date,           -- �f�t�H���g���t
--                       argument5   => NULL,                      -- ����t���b�N�X�t�B�[���h
--                       argument6   => NULL,                      -- ����^�C�v
--                       argument7   => NULL,                      -- (��)������ڋq�ԍ�
--                       argument8   => NULL,                      -- (��)������ڋq�ԍ�
--                       argument9   => NULL,                      -- (��)������ڋq��
--                       argument10  => NULL,                      -- (��)������ڋq��
--                       argument11  => NULL,                      -- (��)GL�L���� 
--                       argument12  => NULL,                      -- (��)GL�L����
--                       argument13  => NULL,                      -- (��)�o�ד� 
--                       argument14  => NULL,                      -- (��)�o�ד�
--                       argument15  => NULL,                      -- (��)����ԍ�
--                       argument16  => NULL,                      -- (��)����ԍ�
--                       argument17  => NULL,                      -- (��)�󒍔ԍ�
--                       argument18  => NULL,                      -- (��)�󒍔ԍ�
--                       argument19  => NULL,                      -- (��)������ 
--                       argument20  => NULL,                      -- (��)������
--                       argument21  => NULL,                      -- (��)�o�א�ڋq�ԍ� 
--                       argument22  => NULL,                      -- (��)�o�א�ڋq�ԍ�
--                       argument23  => NULL,                      -- (��)�o�א�ڋq��
--                       argument24  => NULL,                      -- (��)�o�א�ڋq��
--                       argument25  => 'Y',                       -- (��)���������Ɏx�������v�Z
--                       argument26  => NULL,                      -- (��) �x�������C������
--                       argument27  => gn_org_id                  -- �g�DID
--                     );
----
--    -- �߂�l(�R���J�����g�v��ID)�̔��f
--    -- �R���J�����g������ɔ��s���ꂽ�ꍇ
--    IF (ln_request_id != 0) THEN
----
--      -- �������m��
--      COMMIT;
----
--      -- �R���J�����g�̏I���܂őҋ@
--      lb_request_status := fnd_concurrent.wait_for_request(
--                             request_id => ln_request_id,         -- �v��ID
--                             interval   => gt_taxd_inv_prg_itvl,  -- �`�F�b�N�ҋ@�b��
--                             max_wait   => gt_taxd_inv_prg_wait,  -- �v�������ҋ@�ő�b��
--                             phase      => lv_rphase ,            -- �v���t�F�[�Y
--                             status     => lv_rstatus ,           -- �v���X�e�[�^�X
--                             dev_phase  => lv_dphase,             -- �v���t�F�[�Y�R�[�h
--                             dev_status => lv_dstatus,            -- �v���X�e�[�^�X�R�[�h
--                             message    => lv_message             -- �������b�Z�[�W
--                           );
----
--      -- �߂�l��FALSE�̏ꍇ
--      IF (lb_request_status = FALSE ) THEN
--        -- �G���[���b�Z�[�W�����擾
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                               iv_keyword            => cv_dict_cfr_00303010);
--                                 -- �����C���{�C�X�E�}�X�^�[�E�v���O��������
--        -- �G���[���b�Z�[�W�擾
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00012      -- �R���J�����g�N���G���[���b�Z�[�W
--                               ,iv_token_name1  => cv_tkn_prg_name       -- �g�[�N��'PROGRAM_NAME'
--                               ,iv_token_value1 => lt_look_dict_word
--                               ,iv_token_name2  => cv_tkn_sqlerrm        -- �g�[�N��'SQLERRM'
--                               ,iv_token_value2 => SQLERRM)
--                             ,1
--                             ,5000);
--        lv_errbuf := lv_errmsg;
----
--        -- �G���[���b�Z�[�W�o��
--        fnd_file.put_line(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--        );
----
--        -- �G���[�t���O���Z�b�g
--        lv_conc_err_flg := 'Y';
----
--      END IF;
----
--      -- OUT�p�����[�^.��Ԃ���������
--      -- OUT�p�����[�^.�X�e�[�^�X������ȊO�̏ꍇ
--      IF   (lv_dphase  != cv_conc_phase_cmplt) 
--        OR (lv_dstatus != cv_conc_status_norml)
--      THEN
--        -- �G���[���b�Z�[�W�o��
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00043      -- �����C���{�C�X�����G���[���b�Z�[�W
--                               ,iv_token_name1  => cv_tkn_req_id         -- �g�[�N��'PROGRAM_NAME'
--                               ,iv_token_value1 => TO_CHAR(ln_request_id))
--                             ,1
--                             ,5000);
--        lv_errbuf := lv_errmsg;
----
--        -- �G���[���b�Z�[�W�o��
--        fnd_file.put_line(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--        );
----
--        -- �G���[�t���O���Z�b�g
--        lv_conc_err_flg := 'Y';
----
--      END IF;
----
--    -- �R���J�����g������ɔ��s����Ȃ�����(�v��ID = 0)�ꍇ
--    ELSE
--      -- �G���[���b�Z�[�W�o��
--      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                 iv_keyword            => cv_dict_cfr_00303010);
--                                                            -- �����C���{�C�X�E�}�X�^�[�E�v���O��������
----
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00012      -- �R���J�����g�N���G���[���b�Z�[�W
--                             ,iv_token_name1  => cv_tkn_prg_name       -- �g�[�N��'PROGRAM_NAME'
--                             ,iv_token_value1 => lt_look_dict_word
--                             ,iv_token_name2  => cv_tkn_sqlerrm        -- �g�[�N��'SQLERRM'
--                             ,iv_token_value2 => SQLERRM)
--                           ,1
--                           ,5000);
--      lv_errbuf := lv_errmsg;
----
--      -- �G���[���b�Z�[�W�o��
--      fnd_file.put_line(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
----
--      -- �G���[�t���O���Z�b�g
--      lv_conc_err_flg := 'Y';
----
--    END IF;
----
--    -- �����C���{�C�X�����ŃG���[�����������ꍇ
--    IF (lv_conc_err_flg = 'Y') THEN
--      --==============================================================
--      -- �����C���{�C�X�G���[������
--      --==============================================================
--      -- �J�[�\���I�[�v��
--      OPEN get_inv_err_header_cur(
--             gt_target_request_id
--           );
----
--      -- �f�[�^�̈ꊇ�擾
--      FETCH get_inv_err_header_cur
--      BULK COLLECT INTO lt_del_invoice_id_tab;
----
--      -- ���������̃Z�b�g
--      ln_target_cnt := lt_del_invoice_id_tab.COUNT;
----
--      -- �J�[�\���N���[�Y
--      CLOSE get_inv_err_header_cur;
----
--      -- �Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
--      IF (ln_target_cnt > 0) THEN
----
--        -- �������׏��e�[�u���폜����
--        BEGIN
--          <<del_invoice_lines_loop>>
--          FORALL ln_loop_cnt IN 1..ln_target_cnt
--            DELETE FROM xxcfr_invoice_lines
--            WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--        EXCEPTION
--          -- *** OTHERS��O�n���h�� ***
--          WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00007      -- �e�[�u���폜�G���[
--                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
--                                                                           -- �������׏��e�[�u��
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--        END;
----
--        -- �����w�b�_���e�[�u���폜����
--        BEGIN
--          <<del_invoice_header_loop>>
--          FORALL ln_loop_cnt IN 1..ln_target_cnt
--            DELETE FROM xxcfr_invoice_headers
--            WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--        EXCEPTION
--          -- *** OTHERS��O�n���h�� ***
--          WHEN OTHERS THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                 ,iv_name         => cv_msg_cfr_00007      -- �e�[�u���폜�G���[
--                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                 ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                           -- �����w�b�_���e�[�u��
--                               ,1
--                               ,5000);
--          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--          RAISE global_process_expt;
--        END;
----
--        -- �����f�[�^�폜�������R�~�b�g
--        COMMIT;
----
--        -- ���b�Z�[�W�擾
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr      -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00060    -- �����f�[�^�폜���b�Z�[�W
--                               ,iv_token_name1  => cv_tkn_req_id       -- �g�[�N��'REQUEST_ID'
--                               ,iv_token_value1 => gt_target_request_id)
--                             ,1
--                             ,5000);
----
--        -- �����C���{�C�X�N���G���[�𔭐�
--        RAISE auto_inv_expt;
----
--      END IF;
----
--    END IF;
----
--  EXCEPTION
--    -- *** �����C���{�C�X�N���G���[�n���h�� ***
--    WHEN auto_inv_expt THEN
--      -- �����C���{�C�X�G���[�t���O���Z�b�g
--      gv_auto_inv_err_flag := 'Y';
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** �e�[�u�����b�N�G���[�n���h�� ***
--    WHEN lock_expt THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
--                             ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                       -- �����w�b�_���e�[�u��
--                           ,1
--                           ,5000);
--      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END start_auto_invoice;
-- Modify 2009.09.29 Ver1.5 End
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : end_auto_invoice
--   * Description      : �����C���{�C�X�I������(A-7)
--   ***********************************************************************************/
--  PROCEDURE end_auto_invoice(
--    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  )
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_auto_invoice'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_target_cnt       NUMBER;         -- �Ώی���
--    ln_del_target_cnt   NUMBER;         -- �폜�Ώی���
----
--    -- *** ���[�J���E�J�[�\�� ***
--    -- AR���OIF�G���[���o�J�[�\��
--    CURSOR get_aroif_err_cur
--    IS
--      SELECT DISTINCT
--             hzca.cust_account_id                           cust_account_id,  -- ������ڋqID
--             hzca.account_number                            account_number,   -- ������ڋq�R�[�h
--             xxcfr_common_pkg.get_cust_account_name(
--               hzca.account_number,
--               cv_get_acct_name_f)                          customer_name     -- ������ڋq��
--      FROM   hz_cust_accounts        hzca                       -- �ڋq�}�X�^
--      WHERE  EXISTS (SELECT 'X'
--                     FROM   ra_interface_lines_all  rila            -- AR���OIF
--                           ,xxcfr_tax_gap_trx_list  xxgt            -- �ō��z����쐬
--                           ,hz_cust_accounts        ihzc            -- �ڋq�}�X�^
--                     WHERE  xxgt.request_id = gt_target_request_id  -- �v��ID
--                     AND    rila.interface_line_context = gt_taxd_trx_dtl_cont -- �R���e�L�X�g�l(�ō��z)
--                     AND    rila.line_type = cv_line_type_line                 -- ���׃^�C�v(LINE)
--                     AND    xxgt.bill_cust_code = ihzc.account_number
--                     AND    rila.orig_system_bill_customer_id = ihzc.cust_account_id
--                     AND    rila.orig_system_bill_customer_id = hzca.cust_account_id)
--      ;
----
--    TYPE get_cust_account_id_ttype  IS TABLE OF hz_cust_accounts.cust_account_id%TYPE
--                                      INDEX BY PLS_INTEGER;
--    TYPE get_account_number_ttype   IS TABLE OF hz_cust_accounts.account_number%TYPE
--                                      INDEX BY PLS_INTEGER;
--    TYPE get_customer_name_ttype    IS TABLE OF hz_parties.party_name%TYPE
--                                      INDEX BY PLS_INTEGER;
--    lt_get_cust_acct_id_tab         get_cust_account_id_ttype;
--    lt_get_acct_number_tab          get_account_number_ttype;
--    lt_get_cust_name_tab            get_customer_name_ttype;
----
----
--    -- �����w�b�_�f�[�^�J�[�\��
--    CURSOR get_aroif_err_data_cur(
--      iv_request_id    VARCHAR2,
--      iv_cust_acct_id  NUMBER
--    )
--    IS
--      SELECT xxih.invoice_id    invoice_id
--      FROM   xxcfr_invoice_headers  xxih                  -- �����w�b�_���e�[�u��
--      WHERE  EXISTS (
--               SELECT xxil.invoice_id
--               FROM   xxcfr_invoice_lines   xxil          -- �������׏��e�[�u��
--               WHERE  xxih.invoice_id = xxil.invoice_id
--               )
--      AND    xxih.request_id = iv_request_id              -- �R���J�����g�v��ID
--      AND    xxih.org_id = gn_org_id                      -- �g�DID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- ��v����ID
--      AND    xxih.bill_cust_account_id = iv_cust_acct_id  -- ������ڋqID
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE get_del_invoice_id_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_del_invoice_id_tab           get_del_invoice_id_ttype;  -- �����f�[�^����ID
----
--    -- *** ���[�J���E���R�[�h ***
----
--    -- *** ���[�J����O ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ���[�J���ϐ��̏�����
--    ln_target_cnt     := 0;
--    ln_del_target_cnt := 0;
----
--    --==============================================================
--    --AR���OIF�G���[�f�[�^���o�J�[�\��
--    --==============================================================
--    -- AR���OIF�G���[���o�J�[�\���I�[�v��
--    OPEN get_aroif_err_cur;
----
--    -- �f�[�^�̈ꊇ�擾
--    FETCH get_aroif_err_cur
--    BULK COLLECT INTO lt_get_cust_acct_id_tab,
--                      lt_get_acct_number_tab ,
--                      lt_get_cust_name_tab
--    ;
----
--    -- ���������̃Z�b�g
--    ln_target_cnt := lt_get_cust_acct_id_tab.COUNT;
----
--    -- �J�[�\���N���[�Y
--    CLOSE get_aroif_err_cur;
----
--    --==============================================================
--    --�G���[�f�[�^���O�o�͏���
--    --==============================================================
--    -- �Ώۃf�[�^�����ݎ�
--    IF (ln_target_cnt > 0) THEN
----
--      <<aroif_err_loop>>
--      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--        -- �x���f�[�^�������J�E���g
--        gn_warn_cnt := gn_warn_cnt + 1;
--        -- �x���t���O���Z�b�g����B
--        gv_conc_status := cv_status_warn;
----
--        -- �G���[���b�Z�[�W���擾
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr      -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00044    -- �����f�[�^�폜���b�Z�[�W
--                               ,iv_token_name1  => cv_tkn_cust_code    -- �g�[�N��'CUST_CODE'
--                               ,iv_token_value1 => lt_get_acct_number_tab(ln_loop_cnt)
--                               ,iv_token_name2  => cv_tkn_cust_name    -- �g�[�N��'CUST_NAME'
--                               ,iv_token_value2 => lt_get_cust_name_tab(ln_loop_cnt))
--                             ,1
--                             ,5000);
----
--        -- �G���[���b�Z�[�W�o��
--        fnd_file.put_line(
--           which  => FND_FILE.OUTPUT
--          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--        );
----
--        --==============================================================
--        --�G���[�����f�[�^�폜����
--        --==============================================================
--        -- �����w�b�_�f�[�^�J�[�\��
--        OPEN get_aroif_err_data_cur(
--               gt_target_request_id,
--               lt_get_cust_acct_id_tab(ln_loop_cnt)
--             );
----
--        -- �f�[�^�̈ꊇ�擾
--        FETCH get_aroif_err_data_cur
--        BULK COLLECT INTO lt_del_invoice_id_tab;
----
--        -- �폜���������̃Z�b�g
--        ln_del_target_cnt := lt_del_invoice_id_tab.COUNT;
----
--        -- �����w�b�_�f�[�^�폜����
--        gn_target_del_head_cnt := gn_target_del_head_cnt + ln_del_target_cnt;
----
--        -- �J�[�\���N���[�Y
--        CLOSE get_aroif_err_data_cur;
----
--        -- �폜�Ώۃf�[�^�����݂���ꍇ���R�[�h���폜����
--        IF (ln_del_target_cnt > 0) THEN
----
--          -- �������׏��e�[�u���폜����
--          BEGIN
--            <<del_invoice_lines_loop>>
--            FOR ln_loop_cnt IN 1..ln_del_target_cnt LOOP
--              -- �������׃f�[�^�폜
--              DELETE FROM xxcfr_invoice_lines
--              WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--              -- �������׃f�[�^�폜�����J�E���g
--              gn_target_del_line_cnt := gn_target_del_line_cnt + SQL%ROWCOUNT;
----
--            END LOOP del_invoice_lines_loop;
----
--          EXCEPTION
--            -- *** OTHERS��O�n���h�� ***
--            WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                    iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                   ,iv_name         => cv_msg_cfr_00007      -- �e�[�u���폜�G���[
--                                   ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                   ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxil))
--                                                                             -- �������׏��e�[�u��
--                                 ,1
--                                 ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--          END;
----
--          -- �����w�b�_���e�[�u���폜����
--          BEGIN
--            <<del_invoice_header_loop>>
--            FORALL ln_loop_cnt IN 1..ln_del_target_cnt
--              DELETE FROM xxcfr_invoice_headers
--              WHERE invoice_id = lt_del_invoice_id_tab(ln_loop_cnt);
----
--          EXCEPTION
--            -- *** OTHERS��O�n���h�� ***
--            WHEN OTHERS THEN
--            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                    iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                                   ,iv_name         => cv_msg_cfr_00007      -- �e�[�u���폜�G���[
--                                   ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                                   ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                             -- �����w�b�_���e�[�u��
--                                 ,1
--                                 ,5000);
--            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--            RAISE global_process_expt;
--          END;
----
--        END IF;
----
--      END LOOP aroif_err_loop;
----
--    END IF;
----
--  EXCEPTION
--    -- *** �e�[�u�����b�N�G���[�n���h�� ***
--    WHEN lock_expt THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                             ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
--                             ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                       -- �����w�b�_���e�[�u��
--                           ,1
--                           ,5000);
--      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END end_auto_invoice;
-- Modify 2009.09.29 Ver1.5 End
--
-- Modify 2009.09.29 Ver1.5 Start
--  /**********************************************************************************
--   * Procedure Name   : update_inv_header
--   * Description      : �����w�b�_���X�V����(A-8)
--   ***********************************************************************************/
--  PROCEDURE update_inv_header(
--    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  )
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_inv_header'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_target_cnt       NUMBER;                             -- �Ώی���
----
--    -- *** ���[�J���E�J�[�\�� ***
--    -- �����w�b�_���e�[�u�����b�N�J�[�\��
--    CURSOR get_inv_header_lock_cur
--    IS
--      SELECT xxih.invoice_id    invoice_id
--      FROM   xxcfr_invoice_headers xxih                   -- �����w�b�_���e�[�u��
--      WHERE  xxih.request_id = gt_target_request_id       -- �R���J�����g�v��ID
--      AND    xxih.org_id = gn_org_id                      -- �g�DID
--      AND    xxih.set_of_books_id = gn_set_book_id        -- ��v����ID
--      AND    xxih.tax_gap_trx_id IS NULL                  -- �ō��z���ID
--      AND    xxih.tax_type = cv_tax_div_outtax            -- ����ŋ敪(�O��)
--      FOR UPDATE NOWAIT
--    ;
----
--    TYPE get_upd_invoice_id_ttype   IS TABLE OF xxcfr_invoice_headers.invoice_id%TYPE
--                                             INDEX BY PLS_INTEGER;
--    lt_upd_invoice_id_tab           get_upd_invoice_id_ttype;  -- �����f�[�^����ID
----
--    -- *** ���[�J���E���R�[�h ***
----
--    -- *** ���[�J����O ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  �Œ蕔 END   ############################
----
--    -- ���[�J���ϐ��̏�����
--    ln_target_cnt     := 0;
----
--    --==============================================================
--    --�����w�b�_���e�[�u���X�V����
--    --==============================================================
--    -- �����w�b�_���e�[�u�����b�N
--    BEGIN
----
--      -- �����w�b�_���e�[�u�����b�N�J�[�\���I�[�v��
--      OPEN get_inv_header_lock_cur;
----
--      -- �f�[�^�̈ꊇ�擾
--      FETCH get_inv_header_lock_cur
--      BULK COLLECT INTO lt_upd_invoice_id_tab;
----
--      -- ���������̃Z�b�g
--      ln_target_cnt := lt_upd_invoice_id_tab.COUNT;
----
--      -- �J�[�\���N���[�Y
--      CLOSE get_inv_header_lock_cur;
----
--    EXCEPTION
--      -- *** OTHERS��O�n���h�� ***
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
--                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                         -- �����w�b�_���e�[�u��
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE lock_expt;
--    END;
----
--    BEGIN
--      -- �����w�b�_���e�[�u���X�V
--      UPDATE xxcfr_invoice_headers
--      SET    tax_gap_trx_id = (                   -- �ō��z���ID
--               SELECT MAX(rcta.customer_trx_id)
--               FROM   ra_customer_trx_all   rcta
--               WHERE  rcta.batch_source_id = gt_tax_gap_trx_source_id                        -- ����\�[�XID
--               AND    rcta.bill_to_customer_id = xxcfr_invoice_headers.bill_cust_account_id  -- ������ڋqID
--               AND    rcta.trx_date = xxcfr_invoice_headers.cutoff_date                      -- �����
--               AND    rcta.org_id = xxcfr_invoice_headers.org_id                             -- �g�DID
--               AND    rcta.set_of_books_id = xxcfr_invoice_headers.set_of_books_id           -- ��v����ID
--               )
--      WHERE  request_id = gt_target_request_id       -- �R���J�����g�v��ID
--      AND    org_id = gn_org_id                      -- �g�DID
--      AND    set_of_books_id = gn_set_book_id        -- ��v����ID
--      AND    tax_gap_trx_id IS NULL                  -- �ō��z���ID
--      AND    tax_type = cv_tax_div_outtax            -- ����ŋ敪(�O��)
--      ;
----
--    EXCEPTION
--      -- *** OTHERS��O�n���h�� ***
--      WHEN OTHERS THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00017      -- �e�[�u���X�V�G���[
--                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
--                                                                         -- �����w�b�_���e�[�u��
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
----
--  EXCEPTION
--    -- *** �e�[�u�����b�N�G���[�n���h�� ***
--    WHEN lock_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END update_inv_header;
-- Modify 2009.09.29 Ver1.5 End
--
  /**********************************************************************************
   * Procedure Name   : update_trx_status
   * Description      : ����f�[�^�X�e�[�^�X�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE update_trx_status(
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_trx_status'; -- �v���O������
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
    ln_target_cnt       NUMBER;                             -- �Ώی���
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ����e�[�u�����b�N�J�[�\��
    CURSOR get_cust_trx_lock_cur
    IS
-- Modify 2009.08.03 Ver1.4 Start
--      SELECT rcta.customer_trx_id    customer_trx_id
      SELECT /*+ LEADING(xiit)
                 USE_NL(rcta)
                 INDEX(xxih XXCFR_INVOICE_HEADERS_N02)
                 INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
             */
             rcta.customer_trx_id    customer_trx_id
-- Modify 2009.08.03 Ver1.4 End
      FROM   ra_customer_trx_all     rcta,                -- ����e�[�u��
             xxcfr_invoice_headers   xxih,                -- �����w�b�_���e�[�u��
             xxcfr_inv_info_transfer xiit                 -- ���������n�e�[�u��
      WHERE  rcta.set_of_books_id = xxih.set_of_books_id           -- ��v����ID
      AND    rcta.org_id = xxih.org_id                             -- �g�DID
      AND    rcta.bill_to_customer_id = xxih.bill_cust_account_id  -- ������ڋqID
      AND    rcta.trx_date <= xxih.cutoff_date                     -- �����
      AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                 cv_inv_hold_status_r)             -- �������ۗ��X�e�[�^�X
      AND    xxih.request_id = xiit.target_request_id              -- �v��ID
-- Modify 2012.11.06 Ver1.120 Start
      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'2'(���)
      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- �p���������s�敪����v
      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'0'(�蓮)
      AND     ( xxih.parallel_type     IS NULL ) ) )            -- �p���������s�敪��NULL
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2009.08.03 Ver1.4 Start
--      FOR UPDATE NOWAIT
      FOR UPDATE OF rcta.customer_trx_id NOWAIT -- ����w�b�_�e�[�u���݂̂����b�N
-- Modify 2009.08.03 Ver1.4 End
    ;
--
-- Modify 2013.01.17 Ver1.130 Start
    -- ����e�[�u�����b�N�J�[�\��(�蓮���s�p)
    CURSOR get_manual_cust_trx_lock_cur
    IS
      SELECT /*+ LEADING(xiit)
                 USE_NL(rcta)
                 INDEX(xxih XXCFR_INVOICE_HEADERS_N02)
                 INDEX(rcta XXCFR_RA_CUSTOMER_TRX_N02)
             */
             rcta.customer_trx_id    customer_trx_id
      FROM   ra_customer_trx_all     rcta,                -- ����e�[�u��
             xxcfr_invoice_headers   xxih,                -- �����w�b�_���e�[�u��
             xxcfr_inv_info_transfer xiit                 -- ���������n�e�[�u��
      WHERE  rcta.set_of_books_id = xxih.set_of_books_id           -- ��v����ID
      AND    rcta.org_id = xxih.org_id                             -- �g�DID
      AND    rcta.bill_to_customer_id = xxih.bill_cust_account_id  -- ������ڋqID
      AND    rcta.trx_date <= xxih.cutoff_date                     -- �����
      AND    rcta.attribute7 IN (cv_inv_hold_status_o,
                                 cv_inv_hold_status_r)             -- �������ۗ��X�e�[�^�X
      AND    xxih.request_id = xiit.target_request_id              -- �v��ID
      AND ( ( ( gv_batch_on_judge_type  = cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'2'(���)
      AND     ( xxih.parallel_type      = gn_parallel_type ) )  -- �p���������s�敪����v
      OR    ( ( gv_batch_on_judge_type != cv_judge_type_batch ) -- ��Ԏ蓮���f�敪��'0'(�蓮)
      AND     ( xxih.parallel_type     IS NULL ) ) )            -- �p���������s�敪��NULL
      AND  ( 
             -- �����w�b�_�f�[�^�쐬�p�����[�^������ڋq�ɕR�t���[�i��ڋq�������ΏۂƂ���
             ( EXISTS (
                 SELECT  'X'
                 FROM    hz_cust_acct_relate    bill_hcar
                        ,(
                   SELECT  bill_hzca.account_number    bill_account_number
                          ,ship_hzca.account_number    ship_account_number
                          ,bill_hzca.cust_account_id   bill_account_id
                          ,ship_hzca.cust_account_id   ship_account_id
                   FROM    hz_cust_accounts          bill_hzca
                          ,hz_cust_acct_sites        bill_hzsa
                          ,hz_cust_site_uses         bill_hsua
                          ,hz_cust_accounts          ship_hzca
                          ,hz_cust_acct_sites        ship_hasa
                          ,hz_cust_site_uses         ship_hsua
                   WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
                   AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
                   AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
                   AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
                   AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
                   AND     ship_hzca.customer_class_code = '10'
                   AND     bill_hsua.site_use_code = 'BILL_TO'
                   AND     bill_hsua.status = 'A'
                   AND     ship_hsua.status = 'A'
                 )  ship_cust_info
                 WHERE   rcta.ship_to_customer_id = ship_cust_info.ship_account_id
                 AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
                 AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
                 AND     bill_hcar.attribute1(+) = '1'
                 AND     bill_hcar.status(+)     = 'A'
               AND     ship_cust_info.bill_account_number = gt_bill_acct_code )
             )
             -- �܂��́A�����w�b�_�f�[�^�쐬�p�����[�^������ڋq��14�Ԍڋq�̒P�Ƃő��݂���ꍇ�͏����ΏۂƂ���
         OR ( EXISTS (
                SELECT  'X'
                FROM    hz_cust_accounts          bill_hzca
                WHERE   bill_hzca.cust_account_id = rcta.bill_to_customer_id
                AND     bill_hzca.account_number = gt_bill_acct_code
                AND     rcta.ship_to_customer_id IS NULL )
            )
         )
      FOR UPDATE OF rcta.customer_trx_id NOWAIT -- ����w�b�_�e�[�u���݂̂����b�N
    ;
-- Modify 2013.01.17 Ver1.130 End
--
    TYPE get_upd_trx_id_ttype   IS TABLE OF ra_customer_trx_all.customer_trx_id%TYPE
                                            INDEX BY PLS_INTEGER;
    lt_upd_trx_id_tab           get_upd_trx_id_ttype;  -- ����e�[�u������ID
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
-- Modify 2009.08.03 Ver1.4 Start
    lt_upd_trx_id_tab.DELETE;
-- Modify 2009.08.03 Ver1.4 End
--
    --==============================================================
    --����e�[�u��DFF�������ۗ��X�e�[�^�X�X�V����
    --==============================================================
    -- ����e�[�u�����b�N
--
-- Modify 2013.01.17 Ver1.130 Start
    --��Ԏ蓮���f�敪�̔��f�i��ԃo�b�`�Ǝ蓮���s�ŕ����j
    IF (gv_batch_on_judge_type = cv_judge_type_batch) THEN
-- Modify 2013.01.17 Ver1.130 Start
    OPEN get_cust_trx_lock_cur;
--
-- Modify 2009.08.03 Ver1.4 Start
--    -- �f�[�^�̈ꊇ�擾
--    FETCH get_cust_trx_lock_cur
--    BULK COLLECT INTO lt_upd_trx_id_tab;
----
--    -- ���������̃Z�b�g
--    ln_target_cnt := lt_upd_trx_id_tab.COUNT;
----
--    -- �J�[�\���N���[�Y
--    CLOSE get_cust_trx_lock_cur;
----
--    BEGIN
--      -- ����e�[�u��DFF�X�V
--      UPDATE ra_customer_trx_all
--      SET    attribute7 = cv_inv_hold_status_p    -- �������ۗ��X�e�[�^�X(�����)
--      WHERE  customer_trx_id IN (
--               SELECT rcta.customer_trx_id    customer_trx_id
--               FROM   ra_customer_trx_all     rcta,                -- ����e�[�u��
--                      xxcfr_invoice_headers   xxih,                -- �����w�b�_���e�[�u��
--                      xxcfr_inv_info_transfer xiit                 -- ���������n�e�[�u��
--               WHERE  rcta.set_of_books_id = xxih.set_of_books_id           -- ��v����ID
--               AND    rcta.org_id = xxih.org_id                             -- �g�DID
--               AND    rcta.bill_to_customer_id = xxih.bill_cust_account_id  -- ������ڋqID
--               AND    rcta.trx_date <= xxih.cutoff_date                     -- �����
--               AND    rcta.attribute7 IN (cv_inv_hold_status_o,
--                                          cv_inv_hold_status_r)             -- �������ۗ��X�e�[�^�X
--               AND    xxih.request_id = xiit.target_request_id              -- �v��ID
--               )
--      ;
--    EXCEPTION
--      -- *** OTHERS��O�n���h�� ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                                   iv_loopup_type_prefix => cv_msg_kbn_cfr,
--                                   iv_keyword            => cv_dict_cfr_00303011);
--                                                            -- ����e�[�u��
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
--                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
--                               ,iv_name         => cv_msg_cfr_00017      -- �e�[�u���X�V�G���[
--                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
--                               ,iv_token_value1 => lt_look_dict_word)    -- ����e�[�u��
--                             ,1
--                             ,5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--      END;
    <<main_loop>>
    LOOP
      -- �Ώۃf�[�^���ꊇ�擾(���~�b�g�P��)
      FETCH get_cust_trx_lock_cur BULK COLLECT INTO lt_upd_trx_id_tab LIMIT gn_bulk_limit;
      -- �擾�ł��Ȃ��Ȃ�����I��
      EXIT WHEN lt_upd_trx_id_tab.COUNT < 1;
      --
      BEGIN
        FORALL ln_loop_cnt IN lt_upd_trx_id_tab.FIRST..lt_upd_trx_id_tab.LAST
          UPDATE ra_customer_trx_all rcta
          SET    rcta.attribute7      = cv_inv_hold_status_p    -- �������ۗ��X�e�[�^�X(�����)
-- Modify 2009.11.16 Ver1.7 Start
                ,rcta.last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
                ,rcta.last_update_date       = cd_last_update_date        --�ŏI�X�V��
                ,rcta.last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��
                ,rcta.request_id             = cn_request_id              --�v��ID
                ,rcta.program_application_id = cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
                ,rcta.program_id             = cn_program_id              --�R���J�����g�v���O��
                ,rcta.program_update_date    = cd_program_update_date     --��۸��эX�V��
-- Modify 2009.11.16 Ver1.7 End
          WHERE  rcta.customer_trx_id = lt_upd_trx_id_tab(ln_loop_cnt)
          ;
--
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                     iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                     iv_keyword            => cv_dict_cfr_00303011);
                                                              -- ����e�[�u��
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00017      -- �e�[�u���X�V�G���[
                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                                 ,iv_token_value1 => lt_look_dict_word)    -- ����e�[�u��
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
      -- ������
      lt_upd_trx_id_tab.DELETE;
--
    END LOOP main_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_cust_trx_lock_cur;
--
-- Modify 2009.08.03 Ver1.4 End
-- Modify 2013.01.17 Ver1.130 Start
    --�蓮���s�p
    ELSE
    -- �����w�b�_���e�[�u�����b�N�J�[�\���I�[�v��
    OPEN get_manual_cust_trx_lock_cur;
--
    <<main_manual_loop>>
    LOOP
      -- �Ώۃf�[�^���ꊇ�擾(���~�b�g�P��)
      FETCH get_manual_cust_trx_lock_cur BULK COLLECT INTO lt_upd_trx_id_tab LIMIT gn_bulk_limit;
      -- �擾�ł��Ȃ��Ȃ�����I��
      EXIT WHEN lt_upd_trx_id_tab.COUNT < 1;
      --
      BEGIN
        FORALL ln_loop_cnt IN lt_upd_trx_id_tab.FIRST..lt_upd_trx_id_tab.LAST
          UPDATE ra_customer_trx_all rcta
          SET    rcta.attribute7      = cv_inv_hold_status_p    -- �������ۗ��X�e�[�^�X(�����)
                ,rcta.last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
                ,rcta.last_update_date       = cd_last_update_date        --�ŏI�X�V��
                ,rcta.last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��
                ,rcta.request_id             = cn_request_id              --�v��ID
                ,rcta.program_application_id = cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
                ,rcta.program_id             = cn_program_id              --�R���J�����g�v���O��
                ,rcta.program_update_date    = cd_program_update_date     --��۸��эX�V��
          WHERE  rcta.customer_trx_id = lt_upd_trx_id_tab(ln_loop_cnt)
            ;
--
      EXCEPTION
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                     iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                     iv_keyword            => cv_dict_cfr_00303011);
                                                              -- ����e�[�u��
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                                 ,iv_name         => cv_msg_cfr_00017      -- �e�[�u���X�V�G���[
                                 ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                                 ,iv_token_value1 => lt_look_dict_word)    -- ����e�[�u��
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
--
    -- ������
    lt_upd_trx_id_tab.DELETE;
--
    END LOOP main_manual_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE get_manual_cust_trx_lock_cur;
--
    END IF;
-- Modify 2013.01.17 Ver1.130 End
--
  EXCEPTION
    -- *** �e�[�u�����b�N�G���[�n���h�� ***
    WHEN lock_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( get_manual_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_manual_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
                                 iv_loopup_type_prefix => cv_msg_kbn_cfr,
                                 iv_keyword            => cv_dict_cfr_00303011);
                                                          -- ����e�[�u��
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                             ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                             ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                             ,iv_token_value1 => lt_look_dict_word)    -- ����e�[�u��
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( get_manual_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_manual_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- Modify 2009.08.03 Ver1.4 Start
      IF ( get_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 Start
      ELSIF ( get_manual_cust_trx_lock_cur%ISOPEN ) THEN
        CLOSE get_manual_cust_trx_lock_cur;
-- Modify 2013.01.17 Ver1.130 End
      END IF;
-- Modify 2009.08.03 Ver1.4 End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_trx_status;
--
-- Modify 2013.01.17 Ver1.130 Start
--
  /**********************************************************************************
   * Procedure Name   : get_update_target_bill
   * Description      : �����X�V�Ώێ擾����(A-10)
   ***********************************************************************************/
  PROCEDURE get_update_target_bill(
    ov_target_trx_cnt       OUT NUMBER,       -- �Ώێ������
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_update_target_bill'; -- �v���O������
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
    --�Ώې��������f�[�^���b�N�J�[�\��
    CURSOR lock_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id         invoice_id    -- ������ID
      FROM    xxcfr_invoice_headers xxih            -- �����w�b�_���e�[�u��
      WHERE   xxih.request_id = gt_target_request_id   -- �R���J�����g�v��ID
      FOR UPDATE NOWAIT
      ;
--
    --�Ώې��������擾�J�[�\��
    CURSOR get_target_inv_cur
    IS
      SELECT  /*+ INDEX(xxih XXCFR_INVOICE_HEADERS_N02) */
              xxih.invoice_id         invoice_id    -- ������ID
             ,SUM(NVL(xxil.ship_amount, 0))   ship_amount   -- �[�i���z
             ,SUM(NVL(xxil.tax_amount, 0))    tax_amount    -- ����ŋ��z
             ,SUM(NVL(xxil.ship_amount, 0) + NVL(xxil.tax_amount, 0)) sold_amount  -- ������z
      FROM    xxcfr_invoice_headers xxih            -- �����w�b�_���e�[�u��
             ,xxcfr_invoice_lines   xxil            -- �������׏��e�[�u��
      WHERE   xxih.request_id = gt_target_request_id   -- �R���J�����g�v��ID
      AND     xxih.invoice_id = xxil.invoice_id
      GROUP BY xxih.invoice_id
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ��̏�����
    ov_target_trx_cnt := 0;
--
    --==============================================================
    --�����e�[�u�����b�N���擾����
    --==============================================================
    BEGIN
      OPEN lock_target_inv_cur;
--
      CLOSE lock_target_inv_cur;
--
    EXCEPTION
      -- *** �e�[�u�����b�N�G���[�n���h�� ***
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00003      -- �e�[�u�����b�N�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- �����w�b�_���e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --�����w�b�_���e�[�u���X�V����
    --==============================================================
    --�Ώې��������擾�J�[�\���I�[�v��
    OPEN get_target_inv_cur;
--
-- �f�[�^�̈ꊇ�擾
    FETCH get_target_inv_cur 
    BULK COLLECT INTO gt_get_inv_id_tab
                     ,gt_get_amt_no_tax_tab
                     ,gt_get_tax_amt_sum_tab
                     ,gt_get_amd_inc_tax_tab
    ;
--
    -- ���������̃Z�b�g
    ov_target_trx_cnt := gt_get_inv_id_tab.COUNT;
--
    --�Ώې��������擾�J�[�\���N���[�Y
    CLOSE get_target_inv_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_update_target_bill;
--
--
  /**********************************************************************************
   * Procedure Name   : update_bill_amount
   * Description      : �������z�X�V����(A-11)
   ***********************************************************************************/
  PROCEDURE update_bill_amount(
    in_invoice_id           IN  NUMBER,       -- ������ID
    in_amt_no_tax           IN  NUMBER,       -- �[�i���z
    in_tax_amt_sum          IN  NUMBER,       -- ����ŋ��z
    in_amd_inc_tax          IN  NUMBER,       -- ������z
    ov_errbuf               OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_bill_amount'; -- �v���O������
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
    ln_target_cnt       NUMBER;         -- �Ώی���
    lt_look_dict_word   fnd_lookup_values_vl.meaning%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ��̏�����
    ln_target_cnt     := 0;
--
    -- �����쐬�Ώۃf�[�^�擾
    -- �����w�b�_���Ɛ������׏����쐬�����ɁA���׃f�[�^�폜�݂̂����{���Ă���p�^�[��������
    -- ��L�̏ꍇ�͐����w�b�_�X�V�Ƃ��Č������J�E���g�A�b�v����K�v������ׁA����f�[�^���琿���쐬�Ώۂ����邩���f����
-- Modify 2013.06.10 Ver1.140 Start
--    BEGIN
--
--      SELECT COUNT('X')               cnt    -- ���R�[�h����
--      INTO   ln_target_cnt
--      FROM   ra_customer_trx_all      rcta
--           , xxcfr_invoice_headers    xxih
--      WHERE  xxih.invoice_id           = in_invoice_id                        -- ������ID
--      AND    rcta.trx_date            <= xxih.cutoff_date                     -- ����
--      AND    rcta.bill_to_customer_id  = xxih.bill_cust_account_id            -- ������ڋqID
--      AND    rcta.attribute7 IN (cv_inv_hold_status_o, cv_inv_hold_status_r)  -- �������ۗ��X�e�[�^�X
--      AND    xxih.org_id          = rcta.org_id                               -- �g�DID
--      AND    xxih.set_of_books_id = rcta.set_of_books_id                      -- ��v����ID
--      AND    EXISTS (
--               SELECT  'X'
--               FROM    hz_cust_acct_relate    bill_hcar
--                      ,(
--                 SELECT  bill_hzca.account_number    bill_account_number
--                        ,ship_hzca.account_number    ship_account_number
--                        ,bill_hzca.cust_account_id   bill_account_id
--                        ,ship_hzca.cust_account_id   ship_account_id
--                 FROM    hz_cust_accounts          bill_hzca
--                        ,hz_cust_acct_sites        bill_hzsa
--                        ,hz_cust_site_uses         bill_hsua
--                        ,hz_cust_accounts          ship_hzca
--                        ,hz_cust_acct_sites        ship_hasa
--                        ,hz_cust_site_uses         ship_hsua
--                 WHERE   bill_hzca.cust_account_id   = bill_hzsa.cust_account_id
--                 AND     bill_hzsa.cust_acct_site_id = bill_hsua.cust_acct_site_id
--                 AND     ship_hzca.cust_account_id   = ship_hasa.cust_account_id
--                 AND     ship_hasa.cust_acct_site_id = ship_hsua.cust_acct_site_id
--                 AND     ship_hsua.bill_to_site_use_id = bill_hsua.site_use_id
--                 AND     ship_hzca.customer_class_code = '10'
--                 AND     bill_hsua.site_use_code = 'BILL_TO'
--                 AND     bill_hsua.status = 'A'
--                 AND     ship_hsua.status = 'A'
--               )  ship_cust_info
--               WHERE   rcta.ship_to_customer_id = ship_cust_info.ship_account_id
--               AND     ship_cust_info.bill_account_id = bill_hcar.cust_account_id(+)
--               AND     bill_hcar.related_cust_account_id(+) = ship_cust_info.ship_account_id
--               AND     bill_hcar.attribute1(+) = '1'
--               AND     bill_hcar.status(+)     = 'A'
--               AND     ship_cust_info.bill_account_number = gt_bill_acct_code
--               )
--      ;
--
--    EXCEPTION
--    -- *** OTHERS��O�n���h�� ***
--      WHEN OTHERS THEN
--        lt_look_dict_word := xxcfr_common_pkg.lookup_dictionary(
--                               iv_loopup_type_prefix => cv_msg_kbn_cfr,         -- 'XXCFR'
--                               iv_keyword            => cv_dict_cfr_00302009);  -- �Ώێ���f�[�^����
--        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cfr,               -- 'XXCFR'
--                               iv_name         => cv_msg_cfr_00015,             -- �f�[�^�擾�G���[
--                               iv_token_name1  => cv_tkn_data,
--                               iv_token_value1 => lt_look_dict_word),
--                             1,
--                             5000);
--        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
--        RAISE global_process_expt;
--    END;
--
-- Modify 2013.06.10 Ver1.140 End
--
    -- �����w�b�_���e�[�u���������z�X�V
    BEGIN
--
      UPDATE  xxcfr_invoice_headers  xxih -- �����w�b�_���e�[�u��
      SET     xxih.inv_amount_no_tax      =  in_amt_no_tax  --�Ŕ��������z���v
             ,xxih.tax_amount_sum         =  in_tax_amt_sum --�Ŋz���v
             ,xxih.inv_amount_includ_tax  =  in_amd_inc_tax --�ō��������z���v
      WHERE   xxih.invoice_id = in_invoice_id          -- ������ID
      ;
--
      --==============================================================
      --�����w�b�_�X�V�����J�E���g�A�b�v
      --==============================================================
      -- �����w�b�_�����X�V���Ă���A�������쐬�Ώۂ��Ȃ��ꍇ�A
      -- �����w�b�_�X�V�������J�E���g�A�b�v����(����ȊO�͐��������Ƃ��ăJ�E���g�A�b�v����Ă���)
-- Modify 2013.06.10 Ver1.140 Start
--      IF (SQL%ROWCOUNT > 0) AND (ln_target_cnt = 0) THEN
--        gn_target_up_header_cnt := gn_target_up_header_cnt + 1;
--      END IF;
-- Modify 2013.06.10 Ver1.140 End
--
    EXCEPTION
    -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cfr        -- 'XXCFR'
                               ,iv_name         => cv_msg_cfr_00017      -- �f�[�^�X�V�G���[
                               ,iv_token_name1  => cv_tkn_table          -- �g�[�N��'TABLE'
                               ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table_xxih))
                                                                         -- �����w�b�_���e�[�u��
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_bill_amount;
--
-- Modify 2013.01.17 Ver1.130 End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
-- Modify 2012.11.06 Ver1.120 Start
    iv_parallel_type          IN  VARCHAR2,     -- �p���������s�敪
    iv_batch_on_judge_type    IN  VARCHAR2,     -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
    ov_errbuf                 OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_target_trx_cnt   NUMBER; -- �����Ώێ���f�[�^����
    lv_msg     VARCHAR2(5000);  -- �o�̓��b�Z�[�W
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
    -- <�J�[�\����>
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
    gn_target_header_cnt   := 0;
    gn_target_line_cnt     := 0;
    gn_target_aroif_cnt    := 0;
-- Modify 2012.11.06 Ver1.120 Start
--    gn_target_del_head_cnt := 0;
--    gn_target_del_line_cnt := 0;
--    gn_normal_cnt  := 0;
-- Modify 2012.11.06 Ver1.120 End
    gn_error_cnt   := 0;
-- Modify 2012.11.06 Ver1.120 Start
--    gn_warn_cnt    := 0;
-- Modify 2012.11.06 Ver1.120 End
    gv_conc_status := cv_status_normal;
-- Modify 2012.11.06 Ver1.120 Start
--    gv_auto_inv_err_flag := 'N';
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--    gn_target_up_header_cnt := 0;
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
-- Modify 2012.11.06 Ver1.120 Start
       iv_parallel_type        -- �p���������s�敪
      ,iv_batch_on_judge_type  -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- �Ώې����w�b�_�f�[�^���o���� (A-2)
    -- =====================================================
    get_target_inv_header(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    --�����Ώی�����0���̏ꍇ
    IF (gn_target_header_cnt = 0) THEN
      --�������I������
      RETURN;
    END IF;
--
-- Modify 2009.07.22 Ver1.3 Start
--    --���[�v
--    <<for_loop>>
--    FOR ln_loop_cnt IN gt_invoice_id_tab.FIRST..gt_invoice_id_tab.LAST LOOP
-- Modify 2009.07.22 Ver1.3 End
--
      -- =====================================================
      -- �������׃f�[�^�쐬���� (A-3)
      -- =====================================================
      ins_inv_detail_data(
-- Modify 2009.07.22 Ver1.3 Start
--         gt_invoice_id_tab(ln_loop_cnt),      -- �ꊇ������ID
--         gt_cust_acct_id_tab(ln_loop_cnt),    -- ������ڋqID
--         gt_cutoff_date_tab(ln_loop_cnt),     -- ����
--         gt_tax_type_tab(ln_loop_cnt),        -- ����ŋ敪
-- Modify 2009.07.22 Ver1.3 Start
         lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
         lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
         lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
-- Modify 2009.07.22 Ver1.3 Start
-- Modify 2009.09.29 Ver1.5 Start
--    --���[�v
--    <<for_loop>>
--    FOR ln_loop_cnt IN gt_invoice_id_tab.FIRST..gt_invoice_id_tab.LAST LOOP
---- Modify 2009.07.22 Ver1.3 End
--      -- �ō��z�����������ꍇ
--      IF (NVL(gt_tax_gap_amt_tab(ln_loop_cnt), 0) != 0) THEN
----
--        -- =====================================================
--        -- AR���OIF�o�^���� (A-4)
--        -- =====================================================
--        ins_aroif_data(
--           gt_invoice_id_tab(ln_loop_cnt),      -- �ꊇ������ID
--           gt_tax_gap_amt_tab(ln_loop_cnt),     -- �ō��z
--           gt_term_name_tab(ln_loop_cnt),       -- �x��������
--           gt_term_id_tab(ln_loop_cnt),         -- �x������ID
--           gt_cust_acct_id_tab(ln_loop_cnt),    -- ������ڋqID
--           gt_cust_site_id_tab(ln_loop_cnt),    -- ������ڋq���ݒnID
--           gt_bil_loc_code_tab(ln_loop_cnt),    -- �������_�R�[�h
--           gt_rec_loc_code_tab(ln_loop_cnt),    -- �������_�R�[�h
--           gt_cutoff_date_tab(ln_loop_cnt),     -- ����
--           lv_errbuf,                           -- �G���[�E���b�Z�[�W           --# �Œ� #
--           lv_retcode,                          -- ���^�[���E�R�[�h             --# �Œ� #
--           lv_errmsg);                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        IF (lv_retcode = cv_status_error) THEN
--          --(�G���[����)
--          RAISE global_process_expt;
--        END IF;
----
--      END IF;
----
--    END LOOP for_loop;
----
--    --�����Ώی�����0���̏ꍇ
--    IF  (gn_target_header_cnt = 0) THEN
--      --�������I������
--      RETURN;
--    END IF;
----
--    --AR���OIF�o�^������0���̏ꍇ
--    IF (gn_target_aroif_cnt > 0) THEN
--      -- =====================================================
--      -- �g�����U�N�V�����m�菈�� (A-5)
--      -- =====================================================
--      -- COMMIT�̔��s
--      COMMIT;
----
--      -- COMMIT���s���b�Z�[�W�擾
--      lv_msg := SUBSTRB(xxccp_common_pkg.get_msg(
--                          iv_application  => cv_msg_kbn_cfr,
--                          iv_name         => cv_msg_cfr_00059),
--                        1,
--                        5000);
----
--      -- COMMIT���s�����O�ɏo��
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_msg
--      );
----
--      -- =====================================================
--      -- �����C���{�C�X�N������ (A-6)
--      -- =====================================================
--      start_auto_invoice(
--         lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
--        ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
--        ,lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      IF (lv_retcode = cv_status_error) THEN
--        --(�G���[����)
--        RAISE global_process_expt;
--      END IF;
----
--      -- =====================================================
--      -- �����C���{�C�X�I������ (A-7)
--      -- =====================================================
--      end_auto_invoice(
--         lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
--         lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
--         lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
----
--      IF (lv_retcode = cv_status_error) THEN
--        --(�G���[����)
--        RAISE global_process_expt;
--      END IF;
----
--      -- =====================================================
--      -- �����w�b�_���X�V���� (A-8)
--      -- =====================================================
--      update_inv_header(
--         lv_errbuf,                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
--         lv_retcode,                                 -- ���^�[���E�R�[�h             --# �Œ� #
--         lv_errmsg                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
----
--      IF (lv_retcode = cv_status_error) THEN
--        --(�G���[����)
--        RAISE global_process_expt;
--      END IF;
----
--    END IF;
-- Modify 2009.09.29 Ver1.5 End
--
-- Modify 2013.01.17 Ver1.130 Start
    --��Ԏ蓮���f�敪�̔��f�i�蓮���s�p�j
    --�蓮���s�ł͐����w�b�_���̐������z���Čv�Z����K�v������ׁA���L�ōČv�Z����
    IF (gv_batch_on_judge_type != cv_judge_type_batch) THEN
      --�ϐ�������
      ln_target_trx_cnt := 0;
      -- =====================================================
      -- �����X�V�Ώێ擾���� (A-10)
      -- =====================================================
      get_update_target_bill(
         ln_target_trx_cnt,                      -- �Ώێ������
         lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
         lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
         lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      IF (ln_target_trx_cnt > 0) THEN
      --���[�v
      <<for_loop>>
      FOR ln_loop_cnt IN gt_get_inv_id_tab.FIRST..gt_get_inv_id_tab.LAST LOOP
        -- =====================================================
        -- �������z�X�V���� (A-11)
        -- =====================================================
        update_bill_amount(
           gt_get_inv_id_tab(ln_loop_cnt),         -- ������ID
           gt_get_amt_no_tax_tab(ln_loop_cnt),     -- �[�i���z
           gt_get_tax_amt_sum_tab(ln_loop_cnt),    -- ����ŋ��z
           gt_get_amd_inc_tax_tab(ln_loop_cnt),    -- ������z
           lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
           lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
           lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
      END LOOP for_loop;
--
      END IF;
--
    END IF;
--
-- Modify 2013.01.17 Ver1.130 End
--
    -- =====================================================
    -- ����f�[�^�X�e�[�^�X�X�V���� (A-9)
    -- =====================================================
    update_trx_status(
       lv_errbuf,                              -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,                             -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- �x���t���O���x���ƂȂ��Ă���ꍇ
    IF (gv_conc_status = cv_status_warn) THEN
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := cv_status_warn;
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
    errbuf                  OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W
-- Modify 2012.11.06 Ver1.120 Start
--    retcode                 OUT     VARCHAR2          -- �G���[�R�[�h
    retcode                 OUT     VARCHAR2,         -- �G���[�R�[�h
    iv_parallel_type        IN      VARCHAR2,         -- �p���������s�敪
    iv_batch_on_judge_type  IN      VARCHAR2          -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   -- ���b�Z�[�W�R�[�h
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N���b�Z�[�W
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
      ,ov_retcode => lv_retcode
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
-- Modify 2012.11.06 Ver1.120 Start
       iv_parallel_type          -- �p���������s�敪
      ,iv_batch_on_judge_type    -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.120 End
      ,lv_errbuf                 -- �G���[�E���b�Z�[�W           
      ,lv_retcode                -- ���^�[���E�R�[�h             
      ,lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    --�G���[���b�Z�[�W���ݒ肳��Ă���ꍇ�A�G���[�o��
-- Modify 2013.01.17 Ver1.130 Start
--    IF (lv_errmsg IS NOT NULL) THEN
    IF (lv_retcode = cv_status_error) THEN
-- Modify 2013.01.17 Ver1.130 End
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
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
    --�I���X�e�[�^�X���ُ�I���̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      gn_target_header_cnt := 0;
      gn_target_line_cnt := 0;
-- Modify 2012.11.06 Ver1.120 Start
--      gn_target_del_head_cnt := 0;
--      gn_target_del_line_cnt := 0;
--      gn_normal_cnt := 0;
-- Modify 2012.11.06 Ver1.120 End
      gn_error_cnt  := 1;
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--      gn_target_up_header_cnt := 0;
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
    END IF;
    --
    --���b�Z�[�W�^�C�g��(�w�b�_��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00018
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(�w�b�_��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��(�w�b�_��)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
-- Modify 2013.01.17 Ver1.130 Start
-- Modify 2012.11.06 Ver1.120 Start
--                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt - gn_target_del_head_cnt)
--                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
-- Modify 2012.11.06 Ver1.120 End
-- Modify 2013.06.10 Ver1.140 Start
--                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt - gn_target_up_header_cnt)
                    ,iv_token_value1 => TO_CHAR(gn_target_header_cnt)
-- Modify 2013.01.17 Ver1.130 End
-- Modify 2013.06.10 Ver1.140 End
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��(�w�b�_��)
-- Modify 2012.11.06 Ver1.120 Start
--    IF (lv_retcode = cv_status_error) THEN
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => '1'
--                     );
--
--    ELSE
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => TO_CHAR(gn_target_del_head_cnt)
--                     );
--    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
-- Modify 2012.11.06 Ver1.120 End
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- Modify 2013.06.10 Ver1.140 Start
-- Modify 2013.01.17 Ver1.130 Start
--    --�X�V�����o��(�w�b�_��)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cfr
--                    ,iv_name         => cv_msg_cfr_00146
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR(gn_target_up_header_cnt)
--                   );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- Modify 2013.06.10 Ver1.140 End
    --
-- Modify 2013.01.17 Ver1.130 End
    --���b�Z�[�W�^�C�g��(���ו�)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr
                    ,iv_name         => cv_msg_cfr_00019
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(���ו�)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��(���ו�)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
-- Modify 2012.11.06 Ver1.120 Start
--                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt - gn_target_del_line_cnt)
                    ,iv_token_value1 => TO_CHAR(gn_target_line_cnt)
-- Modify 2012.11.06 Ver1.120 End
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��(���ו�)
-- Modify 2012.11.06 Ver1.120 Start
--    IF (lv_retcode = cv_status_error) THEN
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => '1'
--                     );
--
--    ELSE
--      gv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_ccp
--                      ,iv_name         => cv_msg_ccp_90002
--                      ,iv_token_name1  => cv_tkn_count
--                      ,iv_token_value1 => TO_CHAR(gn_target_del_line_cnt)
--                     );
--    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
-- Modify 2012.11.06 Ver1.120 End
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) 
-- Modify 2012.11.06 Ver1.120 Start
--      AND(gv_auto_inv_err_flag = 'Y')
--    THEN
--      lv_message_code := cv_msg_cfr_00045;
--    ELSIF(lv_retcode = cv_status_error) 
--      AND(gv_auto_inv_err_flag = 'N')
-- Modify 2012.11.06 Ver1.120 End
    THEN
      lv_message_code := cv_msg_cfr_00046;
    END IF;
    --
    --�ُ�I���̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => lv_message_code
                     );
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_ccp
                      ,iv_name         => lv_message_code
                     );
    END IF;
    --
    fnd_file.put_line(
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFR003A03C;
/
