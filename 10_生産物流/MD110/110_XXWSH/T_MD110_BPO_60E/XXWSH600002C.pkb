create or replace PACKAGE BODY xxwsh600002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600002c(body)
 * Description      : ���o�ɔz���v���񒊏o����
 * MD.050           : T_MD050_BPO_601_�z�Ԕz���v��
 * MD.070           : T_MD070_BPO_60E_���o�ɔz���v���񒊏o����
 * Version          : 1.27
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_chk_param          �p�����[�^�`�F�b�N             (E-01)
 *  prc_get_profile        �v���t�@�C���擾               (E-02)
 *  prc_chk_multi          ���d�N���`�F�b�N               -- PT2-2_17�w�E71�Ή� �ǉ�
 *  prc_del_temp_data      �e�[�u���폜                   (E-03)
 *  prc_del_tmptable_data  �e���|�����e�[�u���f�[�^�폜   -- PT2-2_17�w�E71�Ή� �ǉ�
 *  prc_ins_temp_table     ���ԃe�[�u���o�^
 *  prc_get_main_data      ���C���f�[�^���o               (E-04)
 *  prc_get_can_data       ����f�[�^���o                 -- TE080_600�w�E#27�Ή� �ǉ�
 *  prc_get_zero_can_data  �˗����ʃ[������f�[�^���o     -- ����#143�Ή� �ǉ�
 *  prc_cre_head_data      �w�b�_�f�[�^�쐬
 *  prc_cre_dtl_data       ���׃f�[�^�쐬
 *  prc_create_ins_data    �ʒm�Ϗ��쐬����             (E-05)
 *  prc_create_can_data    �ύX�O������f�[�^�쐬����   (E-06)
 *  prc_ins_temp_data      �ꊇ�o�^����                   (E-07)
 *  prc_out_csv_data       �b�r�u�o�͏���                 (E-08,E-09,E-10)
 *  prc_ins_out_data       �ύX�O���폜����             (E-11,E-12)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/01    1.0   M.Ikeda          �V�K�쐬
 *  2008/06/04    1.1   N.Yoshida        �ړ����b�g�ڍוR�t���Ή�
 *  2008/06/05    1.2   M.Hokkanji       �����e�X�g�p�b��Ή�:CSV�o�͏����̏o�͏ꏊ��ύX
 *                                       ���ԃe�[�u���o�^�f�[�^���o����ہA�z�Ԕz���v��A
 *                                       �h�I���Ƀf�[�^�����݂��Ȃ��ꍇ�ł��f�[�^���o�͂�
 *                                       ���悤�ɏC��
 *  2008/06/06    1.3   M.HOKKANJI       �b�r�u�o�͏����ŃG���[��������F_CLOSE_ALL���Ă���̂�
 *                                       �ʂɃN���[�Y����悤�ɕύX
 *  2008/06/06    1.4   M.HOKKANJI       �����e�X�g440�s��Ή�#66
 *  2008/06/06    1.5   M.HOKKANJI       �����e�X�g440�s��Ή�#65
 *  2008/06/11    1.6   M.NOMURA         �����e�X�g WF�Ή�
 *  2008/06/12    1.7   M.NOMURA         �����e�X�g �s��Ή�#9
 *  2008/06/16    1.8   M.NOMURA         �����e�X�g 440 �s��Ή�#64
 *  2008/06/18    1.9   M.HOKKANJI       �V�X�e���e�X�g�s��Ή�#147,#187
 *  2008/06/23    1.10  M.NOMURA         �V�X�e���e�X�g�s��Ή�#217
 *  2008/06/27    1.11  M.NOMURA         �V�X�e���e�X�g�s��Ή�#303
 *  2008/07/04    1.12  M.NOMURA         �V�X�e���e�X�g�s��Ή�#390
 *  2008/07/16    1.13  Oracle �R�� ��_ I_S_192,T_S_443,�w�E240�Ή�
 *  2008/08/04    1.14  M.NOMURA         �ǉ������s��Ή�
 *  2008/08/12    1.15  N.Fukuda         �ۑ�#32�Ή�
 *  2008/08/12    1.15  N.Fukuda         �ۑ�#48(�ύX�v��#164)�Ή�
 *  2008/09/01    1.16  Y.Yamamoto       PT 2-2_17 �w�E17�Ή�
 *  2008/09/09    1.17  N.Fukuda         TE080_600�w�E#30�Ή�
 *  2008/09/10    1.17  N.Fukuda         �Q��View�̕ύX(�p�[�e�B����ڋq�ɕύX)
 *  2008/09/19    1.18  M.Nomura         T_S_453 460 468�Ή�
 *  2008/09/25    1.19  M.Nomura         TE080_600�w�E#31�Ή�
 *  2008/09/25    1.20  M.Nomura         ����#26�Ή�
 *  2008/10/06    1.21  M.Nomura         ����#306�Ή�
 *  2008/10/07    1.22  M.Nomura         TE080_600�w�E#27�Ή�
 *  2008/10/14    1.23  M.Nomura         PT2-2_17�w�E71�Ή�
 *  2008/10/20    1.24  M.Nomura         ����#417�Ή�
 *  2008/10/23    1.25  M.Nomura         T_S_440�Ή�
 *  2008/10/28    1.26  M.Nomura         ����#143�Ή�
 *  2008/11/12    1.27  M.Nomura         ����#626�Ή�
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
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  -- ==============================================================================================
  -- ���[�U�[��`��O
  -- ==============================================================================================
  -- ���b�N�擾��O
  ex_lock_error    EXCEPTION ;
  PRAGMA EXCEPTION_INIT( ex_lock_error, -54 ) ;
--
  -- ==============================================================================================
  -- �O���[�o���萔
  -- ==============================================================================================
  --------------------------------------------------
  -- �p�b�P�[�W��
  --------------------------------------------------
  gc_pkg_name           CONSTANT VARCHAR2(100)  := 'xxwsh600002c';
--
  --------------------------------------------------
  -- �A�v���P�[�V�����Z�k��
  --------------------------------------------------
  gc_appl_sname_cmn     CONSTANT VARCHAR2(100)  := 'XXCMN' ;    -- �}�X�^����
  gc_appl_sname_wsh     CONSTANT VARCHAR2(100)  := 'XXWSH' ;    -- �o��
--
  --------------------------------------------------
  -- �N�C�b�N�R�[�h�i�^�C�v�j
  --------------------------------------------------
  gc_lookup_ship_method     CONSTANT VARCHAR2(50) := 'XXCMN_SHIP_METHOD' ; -- �z���敪
  --------------------------------------------------
  -- �N�C�b�N�R�[�h�i�l�j
  --------------------------------------------------
  -- �\��m��敪
  gc_fix_class_y        CONSTANT VARCHAR2(1) := '1' ;   -- �\��
  gc_fix_class_k        CONSTANT VARCHAR2(1) := '2' ;   -- �m��
  -- �X�e�[�^�X
  gc_req_status_syu_1   CONSTANT VARCHAR2(2) := '01' ;  -- ���͒�
  gc_req_status_syu_2   CONSTANT VARCHAR2(2) := '02' ;  -- ���_�m��
  gc_req_status_syu_3   CONSTANT VARCHAR2(2) := '03' ;  -- ���ߍς�
  gc_req_status_syu_4   CONSTANT VARCHAR2(2) := '04' ;  -- �o�׎��ьv���
  gc_req_status_syu_5   CONSTANT VARCHAR2(2) := '99' ;  -- ���
  gc_req_status_shi_1   CONSTANT VARCHAR2(2) := '05' ;  -- ���͒�
  gc_req_status_shi_2   CONSTANT VARCHAR2(2) := '06' ;  -- ���͊���
  gc_req_status_shi_3   CONSTANT VARCHAR2(2) := '07' ;  -- ��̍�
  gc_req_status_shi_4   CONSTANT VARCHAR2(2) := '08' ;  -- �o�׎��ьv���
  gc_req_status_shi_5   CONSTANT VARCHAR2(2) := '99' ;  -- ���
  -- �ʒm�X�e�[�^�X
  gc_notif_status_n     CONSTANT VARCHAR2(2) := '10' ;  -- ���ʒm
  gc_notif_status_r     CONSTANT VARCHAR2(2) := '20' ;  -- �Ēʒm�v
  gc_notif_status_c     CONSTANT VARCHAR2(2) := '40' ;  -- �m��ʒm��
  -- �d�ʗe�ϋ敪
  gc_wc_class_j         CONSTANT VARCHAR2(1) := '1' ;   -- �d��
  gc_wc_class_y         CONSTANT VARCHAR2(1) := '2' ;   -- �e��
  -- �����敪
  gc_small_method_y     CONSTANT VARCHAR2(1) := '1' ;   -- ����
  gc_small_method_n     CONSTANT VARCHAR2(1) := '0' ;   -- �����ȊO
  -- �x�^�m�t���O
  gc_yes_no_y           CONSTANT VARCHAR2(1) := 'Y' ;   -- �x
  gc_yes_no_n           CONSTANT VARCHAR2(1) := 'N' ;   -- �m
  -- �^���敪
-- 
-- M.Hokkanji Ver1.4 START
--  gc_freight_class_y    CONSTANT VARCHAR2(1) := 'Y' ;   -- �Ώ�
--  gc_freight_class_n    CONSTANT VARCHAR2(1) := 'N' ;   -- �ΏۊO
  gc_freight_class_y    CONSTANT VARCHAR2(1) := '1' ;   -- �Ώ�
  gc_freight_class_n    CONSTANT VARCHAR2(1) := '0' ;   -- �ΏۊO
-- M.Hokkanji Ver1.4 END
  --EOS�Ǘ��敪
  gc_manage_eos_y       CONSTANT VARCHAR2(1) := '1' ;   -- EOS�Ǝ�
  gc_manage_eos_n       CONSTANT VARCHAR2(1) := '0' ;   -- EOS�ȊO
  --�o�׎x���敪
  gc_sp_class_ship        CONSTANT VARCHAR2(1)  := '1' ;    -- �o�׈˗�
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- �x���˗�
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- �ړ��i�v���O����������j
  -- �ړ��X�e�[�^�X
  gc_mov_status_req       CONSTANT VARCHAR2(2)  := '01' ;   -- �˗���
  gc_mov_status_cmp       CONSTANT VARCHAR2(2)  := '02' ;   -- �˗���
  gc_mov_status_adj       CONSTANT VARCHAR2(2)  := '03' ;   -- ������
  gc_mov_status_del       CONSTANT VARCHAR2(2)  := '04' ;   -- �o�ɕ񍐗L
  gc_mov_status_stc       CONSTANT VARCHAR2(2)  := '05' ;   -- ���ɕ񍐗L
  gc_mov_status_dsr       CONSTANT VARCHAR2(2)  := '06' ;   -- ���o�ɕ񍐗L
  gc_mov_status_ccl       CONSTANT VARCHAR2(2)  := '99' ;   -- ���
  -- �ړ��^�C�v
  gc_mov_type_y           CONSTANT VARCHAR2(1)  := '1' ;    -- �ϑ�����
  gc_mov_type_n           CONSTANT VARCHAR2(1)  := '2' ;    -- �ϑ��Ȃ�
  -- ���i�敪
  gc_prod_class_r         CONSTANT VARCHAR2(1)  := '1' ;    -- ���[�t
  gc_prod_class_d         CONSTANT VARCHAR2(1)  := '2' ;    -- �h�����N
  -- �i�ڋ敪
  gc_item_class_g         CONSTANT VARCHAR2(1)  := '1' ;    -- ����
  gc_item_class_s         CONSTANT VARCHAR2(1)  := '2' ;    -- ����
  gc_item_class_h         CONSTANT VARCHAR2(1)  := '4' ;    -- �����i
  gc_item_class_i         CONSTANT VARCHAR2(1)  := '5' ;    -- ���i
  -- ���b�g�Ǘ�
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ���b�g�Ǘ�����
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ���b�g�Ǘ��Ȃ�
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_ship        CONSTANT VARCHAR2(2) := '10' ;    -- �o�׎w��
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;    -- �ړ�
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;    -- �x���w��
  gc_doc_type_prod        CONSTANT VARCHAR2(2) := '40' ;    -- ���Y�w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- �w��
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- �o�Ɏ���
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- ���Ɏ���
  gc_rec_type_tron        CONSTANT VARCHAR2(2) := '40' ;    -- ������
  -- ���b�g�}�X�^�F�L���t���O
  gc_inactive_ind_y       CONSTANT VARCHAR2(1) := '0' ;     -- �L��
  -- ���b�g�}�X�^�F�폜�t���O
  gc_delete_mark_y        CONSTANT VARCHAR2(1) := '0' ;     -- ���폜
--
  --------------------------------------------------
  -- �o�^�l
  --------------------------------------------------
  -- ���׍폜�t���O
  gc_delete_flag_y          CONSTANT VARCHAR2(1) := '1' ;   -- �폜
  gc_delete_flag_n          CONSTANT VARCHAR2(1) := '0' ;   -- ���폜
  -- �f�[�^�^�C�v
  gc_data_type_syu_ins      CONSTANT VARCHAR2(1) := '1' ;   -- �o�ׁF�o�^
  gc_data_type_shi_ins      CONSTANT VARCHAR2(1) := '2' ;   -- �x���F�o�^
  gc_data_type_mov_ins      CONSTANT VARCHAR2(1) := '3' ;   -- �ړ��F�o�^
  gc_data_type_syu_can      CONSTANT VARCHAR2(1) := '7' ;   -- �o�ׁF���
  gc_data_type_shi_can      CONSTANT VARCHAR2(1) := '8' ;   -- �x���F���
  gc_data_type_mov_can      CONSTANT VARCHAR2(1) := '9' ;   -- �ړ��F���
  -- �^���敪
  gc_freight_class_ins_y    CONSTANT VARCHAR2(1) := '1' ;   -- �Ώ�
  gc_freight_class_ins_n    CONSTANT VARCHAR2(1) := '0' ;   -- �ΏۊO
  -- �f�[�^���
  gc_data_class_syu_s       CONSTANT VARCHAR2(3) := '110' ;   -- �o�ׁF�o�׈˗�
  gc_data_class_syu_h       CONSTANT VARCHAR2(3) := '140' ;   -- �o�ׁF�z���˗�
  gc_data_class_shi_s       CONSTANT VARCHAR2(3) := '100' ;   -- �x���F�o�׈˗�
  gc_data_class_shi_h       CONSTANT VARCHAR2(3) := '160' ;   -- �x���F�z���˗�
  gc_data_class_mov_s       CONSTANT VARCHAR2(3) := '120' ;   -- �ړ��F�o�׈˗�
  gc_data_class_mov_h       CONSTANT VARCHAR2(3) := '150' ;   -- �ړ��F�z���˗�
  gc_data_class_mov_n       CONSTANT VARCHAR2(3) := '130' ;   -- �ړ��F�ړ�����
  -- �X�e�[�^�X
  gc_status_y               CONSTANT VARCHAR2(2) := '01' ;    -- �\��
  gc_status_k               CONSTANT VARCHAR2(2) := '02' ;    -- �m��
  -- �f�[�^�敪
  gc_data_class_ins         CONSTANT VARCHAR2(1) := '0' ;     -- �ǉ�
-- M.Hokkanji Ver1.4 START
--  gc_data_class_del         CONSTANT VARCHAR2(1) := '2' ;     -- �폜
  gc_data_class_del         CONSTANT VARCHAR2(1) := '1' ;     -- �폜
-- M.Hokkanji Ver1.4 END
  -- ���[�N�t���[�敪
  gc_wf_class_gai           CONSTANT VARCHAR2(1) := '1' ;     -- �O���q��
  gc_wf_class_uns           CONSTANT VARCHAR2(1) := '2' ;     -- �^���Ǝ�
  gc_wf_class_tor           CONSTANT VARCHAR2(1) := '3' ;     -- �����
  gc_wf_class_hht           CONSTANT VARCHAR2(1) := '4' ;     -- HHT�T�[�o�[
  gc_wf_class_sys           CONSTANT VARCHAR2(1) := '5' ;     -- ���c�ƃV�X�e��
  gc_wf_class_syo           CONSTANT VARCHAR2(1) := '6' ;     -- �E��
--
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
  -- XXCMN�F���i�敪(�Z�L�����e�B)
  gv_prof_item_div_security   CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV_SECURITY';
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
--
  --------------------------------------------------
  -- ���̑�
  --------------------------------------------------
  gc_time_default           CONSTANT VARCHAR2(4) := '0000' ;    -- ���ԃf�t�H���g�l
  gc_time_min               CONSTANT VARCHAR2(5) := '00:00' ;   -- ���ԍŏ��l
  gc_time_max               CONSTANT VARCHAR2(5) := '23:59' ;   -- ���ԍő�l
--
-- ##### 20080611 Ver.1.6 WF�Ή� START #####
  gc_wf_ope_div             CONSTANT VARCHAR2(2) := '09'; -- Workflow�ʒm��i09:�O���q�ɓ��o�Ɂj
-- ##### 20080611 Ver.1.6 WF�Ή� END   #####
--
  -- ==============================================================================================
  -- �O���[�o���ϐ�
  -- ==============================================================================================
  gd_effective_date   DATE ;    -- �}�X�^�i���ݓ��t
  gd_date_from        DATE ;    -- ����tFrom
  gd_date_to          DATE ;    -- ����tTo
  gn_prof_del_date    NUMBER ;  -- �폜�����
--
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
  gd_ship_date_from   DATE ;    -- �o�ɓ�From
  gd_ship_date_to     DATE ;    -- �o�ɓ�To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
--  gv_filetimes        VARCHAR2(14);   -- YYYYMMDDHH24MISS�`��
  gv_filetimes        VARCHAR2(15);   -- YYYYMMDDHH24MISSFF�`��
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
--
-- ##### 20080611 Ver.1.6 WF�Ή� START #####
  gr_wf_whs_rec       xxwsh_common3_pkg.wf_whs_rec ;   -- �t�@�C�����̃��R�[�h�̒�`
-- ##### 20080611 Ver.1.6 WF�Ή� END   #####
--
  gn_created_by               NUMBER ;  -- �쐬��
  gn_last_updated_by          NUMBER ;  -- �ŏI�X�V��
  gn_last_update_login        NUMBER ;  -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER ;  -- �v��ID
  gn_program_application_id   NUMBER ;  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_program_id               NUMBER ;  -- �R���J�����g�E�v���O����ID
--
  gn_out_cnt_syu              NUMBER := 0 ;   -- �o�͌����F�o��
  gn_out_cnt_shi              NUMBER := 0 ;   -- �o�͌����F�x��
  gn_out_cnt_mov              NUMBER := 0 ;   -- �o�͌����F�ړ�
--
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
  gv_item_div_security        VARCHAR2(100);
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
  -- ���d�N���m�F�p
  gv_date_fix          VARCHAR2(20);  -- �m��ʒm���{��
  gv_fix_from          VARCHAR2(10);  -- �m��ʒm���{����From
  gv_fix_to            VARCHAR2(10);  -- �m��ʒm���{����To
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
  --------------------------------------------------
  -- �f�o�b�O�p
  --------------------------------------------------
  gv_debug_txt                VARCHAR2(1000) ;
  gv_debug_cnt                NUMBER := 0 ;
--
  -- ==============================================================================================
  -- ���R�[�h�^�錾
  -- ==============================================================================================
  --------------------------------------------------
  -- ���̓p�����[�^�i�[�p
  --------------------------------------------------
  TYPE rec_param_data  IS RECORD
    (
      dept_code_01      VARCHAR2(4)   -- 01 : ����_01
     ,dept_code_02      VARCHAR2(4)   -- 02 : ����_02(2008/07/16 Add)
     ,dept_code_03      VARCHAR2(4)   -- 03 : ����_03(2008/07/16 Add)
     ,dept_code_04      VARCHAR2(4)   -- 04 : ����_04(2008/07/16 Add)
     ,dept_code_05      VARCHAR2(4)   -- 05 : ����_05(2008/07/16 Add)
     ,dept_code_06      VARCHAR2(4)   -- 06 : ����_06(2008/07/16 Add)
     ,dept_code_07      VARCHAR2(4)   -- 07 : ����_07(2008/07/16 Add)
     ,dept_code_08      VARCHAR2(4)   -- 08 : ����_08(2008/07/16 Add)
     ,dept_code_09      VARCHAR2(4)   -- 09 : ����_09(2008/07/16 Add)
     ,dept_code_10      VARCHAR2(4)   -- 10 : ����_10(2008/07/16 Add)
     ,fix_class         VARCHAR2(1)   -- 02 : �\��m��敪
     ,date_cutoff       VARCHAR2(20)  -- 03 : ���ߎ��{��
     ,cutoff_from       VARCHAR2(10)  -- 04 : ���ߎ��{����From
     ,cutoff_to         VARCHAR2(10)  -- 05 : ���ߎ��{����To
     ,date_fix          VARCHAR2(20)  -- 06 : �m��ʒm���{��
     ,fix_from          VARCHAR2(10)  -- 07 : �m��ʒm���{����From
     ,fix_to            VARCHAR2(10)  -- 08 : �m��ʒm���{����To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
     ,ship_date_from    VARCHAR2(10)  --    : �o�ɓ�From
     ,ship_date_to      VARCHAR2(10)  --    : �o�ɓ�To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
    ) ;
  gr_param              rec_param_data ;
--
  --------------------------------------------------
  -- ���ԃe�[�u���i�[�p
  --------------------------------------------------
  TYPE rec_main_data  IS RECORD
    (
      line_number               xxwsh_stock_delivery_info_tmp2.line_number%TYPE
     ,line_delete_flag          xxwsh_stock_delivery_info_tmp2.line_delete_flag%TYPE
     ,prev_notif_status         xxwsh_stock_delivery_info_tmp2.prev_notif_status%TYPE
     ,data_type                 xxwsh_stock_delivery_info_tmp2.data_type%TYPE
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
     ,eos_shipped_to_locat      xxwsh_stock_delivery_info_tmp2.eos_shipped_to_locat%TYPE
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
     ,eos_shipped_locat         xxwsh_stock_delivery_info_tmp2.eos_shipped_locat%TYPE
     ,eos_freight_carrier       xxwsh_stock_delivery_info_tmp2.eos_freight_carrier%TYPE
     ,delivery_no               xxwsh_stock_delivery_info_tmp2.delivery_no%TYPE
     ,request_no                xxwsh_stock_delivery_info_tmp2.request_no%TYPE
     ,head_sales_branch         xxwsh_stock_delivery_info_tmp2.head_sales_branch%TYPE
     ,head_sales_branch_name    xxwsh_stock_delivery_info_tmp2.head_sales_branch_name%TYPE
     ,shipped_locat_code        xxwsh_stock_delivery_info_tmp2.shipped_locat_code%TYPE
     ,shipped_locat_name        xxwsh_stock_delivery_info_tmp2.shipped_locat_name%TYPE
     ,ship_to_locat_code        xxwsh_stock_delivery_info_tmp2.ship_to_locat_code%TYPE
     ,ship_to_locat_name        xxwsh_stock_delivery_info_tmp2.ship_to_locat_name%TYPE
     ,freight_carrier_code      xxwsh_stock_delivery_info_tmp2.freight_carrier_code%TYPE
     ,freight_carrier_name      xxwsh_stock_delivery_info_tmp2.freight_carrier_name%TYPE
     ,deliver_to                xxwsh_stock_delivery_info_tmp2.deliver_to%TYPE
     ,deliver_to_name           xxwsh_stock_delivery_info_tmp2.deliver_to_name%TYPE
     ,schedule_ship_date        xxwsh_stock_delivery_info_tmp2.schedule_ship_date%TYPE
     ,schedule_arrival_date     xxwsh_stock_delivery_info_tmp2.schedule_arrival_date%TYPE
     ,shipping_method_code      xxwsh_stock_delivery_info_tmp2.shipping_method_code%TYPE
     ,weight                    xxwsh_stock_delivery_info_tmp2.weight%TYPE
     ,mixed_no                  xxwsh_stock_delivery_info_tmp2.mixed_no%TYPE
     ,collected_pallet_qty      xxwsh_stock_delivery_info_tmp2.collected_pallet_qty%TYPE
     ,freight_charge_class      xxwsh_stock_delivery_info_tmp2.freight_charge_class%TYPE
     ,arrival_time_from         xxwsh_stock_delivery_info_tmp2.arrival_time_from%TYPE
     ,arrival_time_to           xxwsh_stock_delivery_info_tmp2.arrival_time_to%TYPE
     ,cust_po_number            xxwsh_stock_delivery_info_tmp2.cust_po_number%TYPE
     ,description               xxwsh_stock_delivery_info_tmp2.description%TYPE
     ,pallet_sum_quantity_out   xxwsh_stock_delivery_info_tmp2.pallet_sum_quantity_out%TYPE
     ,pallet_sum_quantity_in    xxwsh_stock_delivery_info_tmp2.pallet_sum_quantity_in%TYPE
     ,report_dept               xxwsh_stock_delivery_info_tmp2.report_dept%TYPE
     ,prod_class                xxwsh_stock_delivery_info_tmp2.prod_class%TYPE
     ,item_class                xxwsh_stock_delivery_info_tmp2.item_class%TYPE
     ,item_code                 xxwsh_stock_delivery_info_tmp2.item_code%TYPE
     ,item_name                 xxwsh_stock_delivery_info_tmp2.item_name%TYPE
     ,item_uom_code             xxwsh_stock_delivery_info_tmp2.item_uom_code%TYPE
     ,conv_unit                 xxwsh_stock_delivery_info_tmp2.conv_unit%TYPE
     ,item_quantity             xxwsh_stock_delivery_info_tmp2.item_quantity%TYPE
     ,case_quantity             xxwsh_stock_delivery_info_tmp2.case_quantity%TYPE
     ,lot_class                 xxwsh_stock_delivery_info_tmp2.lot_class%TYPE
     ,line_id                   xxwsh_stock_delivery_info_tmp2.line_id%TYPE
     ,item_id                   xxwsh_stock_delivery_info_tmp2.item_id%TYPE
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
     ,notif_date                xxwsh_stock_delivery_info_tmp2.notif_date%TYPE
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
     ,mov_lot_dtl_id            xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
    ) ;
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER ;
  gt_main_data  tab_main_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
--
  TYPE rec_can_data  IS RECORD
    (
      request_no                xxwsh_stock_delivery_info_tmp2.request_no%TYPE
    ) ;
  TYPE tab_can_data IS TABLE OF rec_can_data INDEX BY BINARY_INTEGER ;
  gt_can_data  tab_can_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
--
  TYPE rec_zero_can_data  IS RECORD
    (
      request_no                xxwsh_stock_delivery_info_tmp2.request_no%TYPE
    ) ;
  TYPE tab_zero_can_data IS TABLE OF rec_zero_can_data INDEX BY BINARY_INTEGER ;
  gt_zero_can_data  tab_zero_can_data ;
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
--
  -- ���d�N���`�F�b�N�p �v��ID�擾�p
  TYPE rec_multi_data  IS RECORD
    (
      request_id        NUMBER(15,0)
    ) ;
  TYPE tab_multi_data IS TABLE OF rec_multi_data INDEX BY BINARY_INTEGER ;
  gt_multi_data  tab_multi_data ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
  --------------------------------------------------
  -- �ʒm�Ϗ��i�[�p
  --------------------------------------------------
  TYPE t_corporation_name        IS TABLE OF
       xxwsh_stock_delivery_info_tmp.corporation_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_class              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.data_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_transfer_branch_no      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.transfer_branch_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_delivery_no             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.delivery_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_request_no              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.request_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve                 IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.head_sales_branch%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_head_sales_branch_name  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.head_sales_branch_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_code      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.shipped_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipped_locat_name      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.shipped_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_code      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.ship_to_locat_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_ship_to_locat_name      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.ship_to_locat_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_code    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_carrier_name    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.freight_carrier_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.deliver_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_deliver_to_name         IS TABLE OF
       xxwsh_stock_delivery_info_tmp.deliver_to_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_ship_date      IS TABLE OF
       xxwsh_stock_delivery_info_tmp.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_schedule_arrival_date   IS TABLE OF
       xxwsh_stock_delivery_info_tmp.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_shipping_method_code    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.shipping_method_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_weight                  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.weight%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_mixed_no                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.mixed_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_collected_pallet_qty    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_from       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.arrival_time_from%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_arrival_time_to         IS TABLE OF
       xxwsh_stock_delivery_info_tmp.arrival_time_to%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_cust_po_number          IS TABLE OF
       xxwsh_stock_delivery_info_tmp.cust_po_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_description             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.description%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_status                  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.status%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_freight_charge_class    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.freight_charge_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_pallet_sum_quantity     IS TABLE OF
       xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve1                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve1%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve2                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve2%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve3                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve3%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_reserve4                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.reserve4%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_report_dept             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.report_dept%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_code               IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_name               IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_name%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_uom_code           IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_item_quantity           IS TABLE OF
       xxwsh_stock_delivery_info_tmp.item_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_no                  IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_no%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_date                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_best_bfr_date           IS TABLE OF
       xxwsh_stock_delivery_info_tmp.best_bfr_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_sign                IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_sign%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_lot_quantity            IS TABLE OF
       xxwsh_stock_delivery_info_tmp.lot_quantity%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_new_modify_del_class    IS TABLE OF
       xxwsh_stock_delivery_info_tmp.new_modify_del_class%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_update_date             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.update_date%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_line_number             IS TABLE OF
       xxwsh_stock_delivery_info_tmp.line_number%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_data_type               IS TABLE OF
       xxwsh_stock_delivery_info_tmp.data_type%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_eos_shipped_locat       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_eos_freight_carrier     IS TABLE OF
       xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE INDEX BY BINARY_INTEGER ;
  TYPE t_eos_csv_output          IS TABLE OF
       xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
  TYPE t_notif_date              IS TABLE OF
       xxwsh_stock_delivery_info_tmp.notif_date%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
  TYPE t_target_request_id       IS TABLE OF
       xxwsh_stock_delivery_info_tmp.target_request_id%TYPE INDEX BY BINARY_INTEGER ;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
  gt_corporation_name        t_corporation_name ;
  gt_data_class              t_data_class ;
  gt_transfer_branch_no      t_transfer_branch_no ;
  gt_delivery_no             t_delivery_no ;
  gt_request_no              t_request_no ;
  gt_reserve                 t_reserve ;
  gt_head_sales_branch       t_head_sales_branch ;
  gt_head_sales_branch_name  t_head_sales_branch_name ;
  gt_shipped_locat_code      t_shipped_locat_code ;
  gt_shipped_locat_name      t_shipped_locat_name ;
  gt_ship_to_locat_code      t_ship_to_locat_code ;
  gt_ship_to_locat_name      t_ship_to_locat_name ;
  gt_freight_carrier_code    t_freight_carrier_code ;
  gt_freight_carrier_name    t_freight_carrier_name ;
  gt_deliver_to              t_deliver_to ;
  gt_deliver_to_name         t_deliver_to_name ;
  gt_schedule_ship_date      t_schedule_ship_date ;
  gt_schedule_arrival_date   t_schedule_arrival_date ;
  gt_shipping_method_code    t_shipping_method_code ;
  gt_weight                  t_weight ;
  gt_mixed_no                t_mixed_no ;
  gt_collected_pallet_qty    t_collected_pallet_qty ;
  gt_arrival_time_from       t_arrival_time_from ;
  gt_arrival_time_to         t_arrival_time_to ;
  gt_cust_po_number          t_cust_po_number ;
  gt_description             t_description ;
  gt_status                  t_status ;
  gt_freight_charge_class    t_freight_charge_class ;
  gt_pallet_sum_quantity     t_pallet_sum_quantity ;
  gt_reserve1                t_reserve1 ;
  gt_reserve2                t_reserve2 ;
  gt_reserve3                t_reserve3 ;
  gt_reserve4                t_reserve4 ;
  gt_report_dept             t_report_dept ;
  gt_item_code               t_item_code ;
  gt_item_name               t_item_name ;
  gt_item_uom_code           t_item_uom_code ;
  gt_item_quantity           t_item_quantity ;
  gt_lot_no                  t_lot_no ;
  gt_lot_date                t_lot_date ;
  gt_best_bfr_date           t_best_bfr_date ;
  gt_lot_sign                t_lot_sign ;
  gt_lot_quantity            t_lot_quantity ;
  gt_new_modify_del_class    t_new_modify_del_class ;
  gt_update_date             t_update_date ;
  gt_line_number             t_line_number ;
  gt_data_type               t_data_type ;
  gt_eos_shipped_locat       t_eos_shipped_locat ;
  gt_eos_freight_carrier     t_eos_freight_carrier ;
  gt_eos_csv_output          t_eos_csv_output ;
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
  gt_notif_date              t_notif_date ;
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
  gt_target_request_id       t_target_request_id ;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
  gn_cre_idx    NUMBER := 0 ;
--
  -- �x�����b�Z�[�W�p�z��ϐ�
  TYPE t_worm_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_worm_msg     t_worm_msg ;
  gn_wrm_idx      NUMBER := 0 ;
--
-- ##### 20081023 Ver.1.25 T_S_440�Ή� START #####
  -- �ʒm����i���ʃ��|�[�g�o�͗p�j
  TYPE t_notif_msg IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER ;
  gt_notif_msg     t_notif_msg ;
  gn_notif_idx      NUMBER := 0 ;
-- ##### 20081023 Ver.1.25 T_S_440�Ή� END   #####
--
  /***********************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : �p�����[�^�`�F�b�N(E-01)
   ***********************************************************************************************/
  PROCEDURE prc_chk_param
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_param' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_p_name_date_cutoff   CONSTANT VARCHAR2(50) := '���ߎ��{��' ;
    lc_p_name_time_cutoff   CONSTANT VARCHAR2(50) := '���ߎ��{����' ;
    lc_p_name_date_fix      CONSTANT VARCHAR2(50) := '�m��ʒm���{��' ;
    lc_p_name_time_fix      CONSTANT VARCHAR2(50) := '�m��ʒm���{����' ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
    lc_p_name_shipdateF     CONSTANT VARCHAR2(50) := '�o�ɓ�From' ;
    lc_p_name_shipdateT     CONSTANT VARCHAR2(50) := '�o�ɓ�To' ;
    lc_p_name_shipdate      CONSTANT VARCHAR2(50) := '�o�ɓ�' ;
    lc_msg_code_03          CONSTANT VARCHAR2(50) := 'APP-XXWSH-11114' ;  -- ���t�͈̓G���[���b�Z�[�W
    lc_tok_name_02          CONSTANT VARCHAR2(50) := 'DATE_NAME' ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
    lc_msg_code_01          CONSTANT VARCHAR2(50) := 'APP-XXWSH-11251' ;  -- ������
    lc_msg_code_02          CONSTANT VARCHAR2(50) := 'APP-XXWSH-11905' ;  -- ���ԋt�]
    lc_tok_name             CONSTANT VARCHAR2(50) := 'PARAMETER' ;
--
    lc_date_format          CONSTANT VARCHAR2(50) := 'YYYY/MM/DD HH24:MI:SS' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
    lv_tok_val        VARCHAR2(100) ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
    lv_tok_name       VARCHAR2(100) ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_param_error    EXCEPTION ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
    ex_param_error_02 EXCEPTION ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �\��m��敪���u�\��v�̏ꍇ
    -- ====================================================
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
--
      gr_param.date_cutoff := NVL( gr_param.date_cutoff, TO_CHAR( SYSDATE, 'YYYY/MM/DD' ) ) ;
      gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff ) ;
      gd_date_from  := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff || gr_param.cutoff_from ) ;
      gd_date_to    := FND_DATE.CANONICAL_TO_DATE( gr_param.date_cutoff || gr_param.cutoff_to ) ;
--
      -- ----------------------------------------------------
      -- �t�]�`�F�b�N
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_02 ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
      lv_tok_name := lc_tok_name ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
      IF ( gd_date_from > gd_date_to ) THEN
        lv_tok_val := lc_p_name_time_cutoff ;
        RAISE ex_param_error ;
      END IF ;
--
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
      -- ----------------------------------------------------
      -- �K�{�`�F�b�N
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_01 ;
      lv_tok_name := lc_tok_name ;
      -- �o�ɓ�From
      IF ( gr_param.ship_date_from IS NULL ) THEN
        lv_tok_val  := lc_p_name_shipdateF ;
        RAISE ex_param_error ;
      END IF ;
--
      -- �o�ɓ�To
      IF ( gr_param.ship_date_to IS NULL ) THEN
        lv_tok_val  := lc_p_name_shipdateT ;
        RAISE ex_param_error ;
      END IF ;
--
      -- �o�ɓ�From
      gd_ship_date_from := FND_DATE.CANONICAL_TO_DATE( gr_param.ship_date_from ) ;
      -- �o�ɓ�To
      gd_ship_date_to   := FND_DATE.CANONICAL_TO_DATE( gr_param.ship_date_to ) ;
--
      -- ----------------------------------------------------
      -- ���t�͈̓G���[���b�Z�[�W
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_03 ;
      lv_tok_name := lc_tok_name_02 ;
      IF ( gd_ship_date_from > gd_ship_date_to ) THEN
        lv_tok_val := lc_p_name_shipdate ;
        RAISE ex_param_error ;
      END IF ;
--
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
--
    -- ====================================================
    -- �\��m��敪���u�m��v�̏ꍇ
    -- ====================================================
    ELSE
      -- ----------------------------------------------------
      -- �K�{�`�F�b�N
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_01 ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
      lv_tok_name := lc_tok_name ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
      -- �m��ʒm���{��
      IF ( gr_param.date_fix IS NULL ) THEN
        lv_tok_val  := lc_p_name_date_fix ;
        RAISE ex_param_error ;
      END IF ;
--
      gd_effective_date := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix ) ;
      gd_date_from  := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_from ) ;
      gd_date_to    := FND_DATE.CANONICAL_TO_DATE( gr_param.date_fix || gr_param.fix_to ) ;
--
      -- ----------------------------------------------------
      -- �t�]�`�F�b�N
      -- ----------------------------------------------------
      lv_msg_code := lc_msg_code_02 ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
      lv_tok_name := lc_tok_name ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
      IF ( gd_date_from > gd_date_to ) THEN
        lv_tok_val := lc_p_name_date_fix ;
        RAISE ex_param_error ;
      END IF ;
--
    END IF ;
--
  EXCEPTION
    -- ============================================================================================
    -- �p�����[�^�G���[
    -- ============================================================================================
    WHEN ex_param_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lv_msg_code
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
--                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_name1    => lv_tok_name
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
                     ,iv_token_value1   => lv_tok_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   ######################################################################
  END prc_chk_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_profile
   * Description      : �v���t�@�C���擾(E-02)
   ***********************************************************************************************/
  PROCEDURE prc_get_profile
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_profile' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_prof_name    CONSTANT VARCHAR2(50) := 'XXWSH_PURGE_PERIOD_601' ;
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-11953' ;
    lc_tok_name     CONSTANT VARCHAR2(50) := 'PROF_NAME' ;
    lc_tok_val      CONSTANT VARCHAR2(50) := 'XXWSH: �ʒm�Ϗ��p�[�W�����Ώۊ���_�z�Ԕz���v��' ;
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
    lc_tok_val2     CONSTANT VARCHAR2(50) := '���i�敪�i�Z�L�����e�B�j' ;
    lv_tok_val      VARCHAR2(50);
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_prof_error     EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--

-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
  -- ====================================================
  -- ��������
  -- ====================================================
  --�t�@�C�����^�C���X�^���v�擾
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
--  gv_filetimes  := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
    gv_filetimes  := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF1');
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
    -- ====================================================
    -- �v���t�@�C���擾
    -- ====================================================
    gn_prof_del_date := FND_PROFILE.VALUE( lc_prof_name ) ;
    IF ( gn_prof_del_date IS NULL ) THEN
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
      lv_tok_val := lc_tok_val;
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
      RAISE ex_prof_error ;
    END IF ;
--
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
    -- ���i�敪�i�Z�L�����e�B�j�擾
    gv_item_div_security := FND_PROFILE.VALUE(gv_prof_item_div_security);
    IF (gv_item_div_security IS NULL) THEN
      lv_tok_val := lc_tok_val2;
      RAISE ex_prof_error ;
    END IF;
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
--
  EXCEPTION
    -- ============================================================================================
    -- �v���t�@�C���擾�G���[
    -- ============================================================================================
    WHEN ex_prof_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                     ,iv_token_name1    => lc_tok_name
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
                     ,iv_token_value1   => lv_tok_val
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_get_profile ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_multi
   * Description      : ���d�N���`�F�b�N
   ***********************************************************************************************/
  PROCEDURE prc_chk_multi
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_multi' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code CONSTANT VARCHAR2(50) := 'APP-XXWSH-11901' ;  -- ���d�N��
    lc_tok_name CONSTANT VARCHAR2(50) := 'REQ_ID' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
    lv_tkn_val        VARCHAR2(100) ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_multi_error     EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
  -- ==============================================================
  -- �R���J�����g�v���O����ID���N�����̓����v���O��������������
  --  �ȉ��̏����ɑS�Ċ܂܂��ꍇ�͑��d�N���Ɣ��f����
  --   �E����01�`10�̒��Ō��݋N�����Ă��镔���Ɠ������������݂���
  --   �E�m��ʒm�����{��������
  --   �E�m��ʒm�����{���Ԃ�From-To�ɂ��Ă̎��Ԃ��܂܂��
  -- ==============================================================
  SELECT request_id
  BULK COLLECT INTO gt_multi_data
  FROM   fnd_concurrent_requests fcr
  WHERE  fcr.phase_code = 'R'           -- ���s��
  -- �v���O����ID���R���J�����gID���擾
  AND  exists (select 'x' 
                FROM  fnd_concurrent_programs fcp1
                    , fnd_concurrent_programs fcp2
                WHERE fcp1.concurrent_program_id = fcr.concurrent_program_id
                AND   fcp1.executable_id         = fcp2.executable_id
                AND   fcp2.concurrent_program_id = gn_program_id        -- �R���J�����g�v���O����ID
                )
  -- ����01
  AND (gr_param.dept_code_01 IN ( fcr.argument1, fcr.argument2, 
                                  fcr.argument3, fcr.argument4, 
                                  fcr.argument5, fcr.argument6, 
                                  fcr.argument7, fcr.argument8, 
                                  fcr.argument9, fcr.argument10)
    -- ����02�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_02, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����03�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_03, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����04�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_04, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����05�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_05, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����06�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_06, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����07�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_07, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����08�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_08, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����09�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_09, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10)
    -- ����10�iNULL�̏ꍇ�� ����01�Ɣ�r�j
    OR NVL(gr_param.dept_code_10, gr_param.dept_code_01) IN ( fcr.argument1, fcr.argument2, 
                                                              fcr.argument3, fcr.argument4, 
                                                              fcr.argument5, fcr.argument6, 
                                                              fcr.argument7, fcr.argument8, 
                                                              fcr.argument9, fcr.argument10))
  -- �\��m��敪
  AND fcr.argument11 = '2'  -- �m��
  -- �m��ʒm���{��
  AND fcr.argument15 = gv_date_fix
  AND 
    -- �m��ʒm���{����From
    (
      ( FND_DATE.STRING_TO_DATE(fcr.argument16, 'HH24:MI') <= FND_DATE.STRING_TO_DATE(gv_fix_from, 'HH24:MI')
    AND FND_DATE.STRING_TO_DATE(fcr.argument17, 'HH24:MI') >= FND_DATE.STRING_TO_DATE(gv_fix_from, 'HH24:MI'))
  OR
    -- �m��ʒm���{����To
      ( FND_DATE.STRING_TO_DATE(fcr.argument16, 'HH24:MI') <= FND_DATE.STRING_TO_DATE(gv_fix_to, 'HH24:MI')
    AND FND_DATE.STRING_TO_DATE(fcr.argument17, 'HH24:MI') >= FND_DATE.STRING_TO_DATE(gv_fix_to, 'HH24:MI'))
    )
  -- �����̗v��ID�����Â����̂�Ώ�
  AND request_id < gn_request_id
  ;
--
  -- �f�[�^�����݂����ꍇ
  IF ( gt_multi_data.COUNT <> 0 ) THEN
--
    -- �����ݒ�
    lv_tkn_val := NULL;
--
    <<msg_loop>>
    FOR i IN 1..gt_multi_data.COUNT LOOP
      -- 2�ȏ㑶�݂���ꍇ�͋�؂蕶���� , ��t�^
      IF ( i > 1 ) THEN
        lv_tkn_val := lv_tkn_val || ',' ;
      END IF;
      -- �v��ID���g�[�N���Ɋi�[
      lv_tkn_val := lv_tkn_val || gt_multi_data(i).request_id;
    END LOOP msg_loop;
--
    -- ���d�N���G���[�Ƃ���
    RAISE ex_multi_error;
  END IF;
--
  EXCEPTION
    -- ============================================================================================
    -- ���d�N���G���[
    -- ============================================================================================
    WHEN ex_multi_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                     ,iv_token_name1    => lc_tok_name
                     ,iv_token_value1   => lv_tkn_val
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--##### �Œ��O������ START ######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_chk_multi ;
--
  /************************************************************************************************
   * Procedure Name   : prc_del_tmptable_data
   * Description      : �e���|�����e�[�u���f�[�^�폜
   ************************************************************************************************/
  PROCEDURE prc_del_tmptable_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_del_tmptable_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �f�[�^�폜
    -- ====================================================
    -- �v��ID���L�[�ɍ폜
    DELETE FROM xxwsh_stock_delivery_info_tmp  
    WHERE target_request_id = gn_request_id;
--
    -- �v��ID���L�[�ɍ폜
    DELETE FROM xxwsh_stock_delivery_info_tmp2 
    WHERE target_request_id = gn_request_id;
--
  EXCEPTION
--
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_del_tmptable_data ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
  /************************************************************************************************
   * Procedure Name   : prc_del_temp_data
   * Description      : �f�[�^�폜(E-03)
   ************************************************************************************************/
  PROCEDURE prc_del_temp_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_del_temp_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-12853' ;
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    ----------------------------------------
    -- ���o�ɔz���v���񒆊ԃe�[�u��
    ----------------------------------------
    CURSOR cu_del_table_01
    IS
      SELECT xsdit.request_no
      FROM xxwsh_stock_delivery_info_tmp xsdit
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
      WHERE  xsdit.notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FOR UPDATE NOWAIT
    ;
    ----------------------------------------
    -- �f�[�^���o�p���ԃe�[�u��
    ----------------------------------------
    CURSOR cu_del_table_02
    IS
      SELECT xsdit2.request_no
      FROM xxwsh_stock_delivery_info_tmp2 xsdit2
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
      WHERE xsdit2.notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FOR UPDATE NOWAIT
    ;
    ----------------------------------------
    -- �ʒm�ϓ��o�ɔz���v����i�A�h�I���j
    ----------------------------------------
    CURSOR cu_del_table_03
    IS
      SELECT xndi.request_no
      FROM xxwsh_notif_delivery_info xndi
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      WHERE TRUNC( xndi.last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date
      WHERE  xndi.last_update_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1
-- 2008/09/01 v1.16 update Y.Yamamoto end
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���b�N�擾
    -- ====================================================
    <<get_lock_01>>
    FOR re_del_table_01 IN cu_del_table_01 LOOP
      EXIT ;
    END LOOP get_lock_01 ;
    <<get_lock_02>>
    FOR re_del_table_02 IN cu_del_table_02 LOOP
      EXIT ;
    END LOOP get_lock_02 ;
    <<get_lock_03>>
    FOR re_del_table_03 IN cu_del_table_03 LOOP
      EXIT ;
    END LOOP get_lock_03 ;
--
    -- ====================================================
    -- �f�[�^�폜
    -- ====================================================
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
/*****
    DELETE FROM xxwsh_stock_delivery_info_tmp ;
    DELETE FROM xxwsh_stock_delivery_info_tmp2 ;
*****/
    -- �m��ʒm�����̃p�[�W�����ȑO���폜
    DELETE FROM xxwsh_stock_delivery_info_tmp  
    WHERE  notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1 ;
--
    -- �m��ʒm�����̃p�[�W�����ȑO���폜
    DELETE FROM xxwsh_stock_delivery_info_tmp2 
    WHERE  notif_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1 ;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
    DELETE FROM xxwsh_notif_delivery_info
-- 2008/09/01 v1.16 update Y.Yamamoto start
--    WHERE TRUNC( last_update_date ) <= TRUNC( SYSDATE ) - gn_prof_del_date ;
    WHERE  last_update_date < TRUNC( SYSDATE ) - gn_prof_del_date + 1 ;
-- 2008/09/01 v1.16 update Y.Yamamoto end
--
  EXCEPTION
    -- =============================================================================================
    -- ���b�N�擾�G���[
    -- =============================================================================================
    WHEN ex_lock_error THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_del_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_table
   * Description      : ���ԃe�[�u���o�^
   ************************************************************************************************/
  PROCEDURE prc_ins_temp_table
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_temp_table' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �ϐ���`
    -- ==================================================
    lv_cnt    NUMBER := 0 ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���ԃe�[�u���o�^
    -- ====================================================
-- 2008/09/01 v1.16 update Y.Yamamoto start
    -- ====================================================
    -- �p�t�H�[�}���X�Ή��̂��߁A1��SQL��\��m��敪���Ƃɕ���
    -- �\��m��敪���u�\��v�̏ꍇ
    -- ====================================================
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
--
    INSERT INTO xxwsh_stock_delivery_info_tmp2
      -- ===========================================================================================
      -- �o�׃f�[�^�r�p�k
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:���הԍ�
            ,xola.order_line_id                       -- 02:����ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:���׍폜�t���O
            ,xoha.req_status                          -- 04:�X�e�[�^�X
            ,xoha.notif_status                        -- 05:�ʒm�X�e�[�^�X
            ,xoha.prev_notif_status                   -- 06:�O��ʒm�X�e�[�^�X
            ,CASE
               WHEN xoha.req_status = gc_req_status_syu_5 THEN gc_data_type_syu_can
               ELSE gc_data_type_syu_ins
             END                                      -- 07:�f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
            ,NULL                                     -- XX:EOS����i���ɑq�Ɂj
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
            ,xil.eos_detination                       -- 08:EOS����i�o�ɑq�Ɂj
            ,xc.eos_detination                        -- 09:EOS����i�^���Ǝҁj
            ,xoha.delivery_no                         -- 10:�z��No
            ,xoha.request_no                          -- 11:�˗�No
            --,xp.party_number                          -- 12:���_�R�[�h   -- 2008/09/10 �Q��View�ύX Del
            --,xp.party_name                            -- 13:�Ǌ����_���� -- 2008/09/10 �Q��View�ύX Del
            ,xca.party_number                         -- 12:���_�R�[�h     -- 2008/09/10 �Q��View�ύX Add
            ,xca.party_name                           -- 13:�Ǌ����_����   -- 2008/09/10 �Q��View�ύX Add
            ,xil.segment1                             -- 14:�o�ɑq�ɃR�[�h
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:�o�ɑq�ɖ���
            ,NULL                                     -- 16:���ɑq�ɃR�[�h
            ,NULL                                     -- 17:���ɑq�ɖ���
            ,xc.party_number                          -- 18:�^���Ǝ҃R�[�h
            ,xc.party_name                            -- 19:�^���ƎҖ�
            --,xps.party_site_number                    -- 20:�z����R�[�h  -- 2008/09/10 �Q��View�ύX Del
            --,xps.party_site_full_name                 -- 21:�z���於      -- 2008/09/10 �Q��View�ύX Del
            ,xcas.party_site_number                   -- 20:�z����R�[�h    -- 2008/09/10 �Q��View�ύX Add
            ,xcas.party_site_full_name                -- 21:�z���於        -- 2008/09/10 �Q��View�ύX Add
            ,xoha.schedule_ship_date                  -- 22:����
            ,xoha.schedule_arrival_date               -- 23:����
            ,xlv.lookup_code                          -- 24:�z���敪
            ,CASE
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6              = gc_small_method_y THEN xoha.sum_weight      --2008/08/12 Del �ۑ�#48(�ύX#164)
               AND  xlv.attribute6              = gc_small_method_y THEN NVL(xoha.sum_weight,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
-- M.HOKKANJI Ver1.2 START
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xoha.sum_weight,0)
                                                                      + NVL(xoha.sum_pallet_weight,0)
--               AND  xlv.attribute6             <> gc_small_method_y THEN xoha.sum_weight
--                                                                      + xoha.sum_pallet_weight
-- M.HOKKANJI Ver1.2 END
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN xoha.sum_capacity      --2008/08/12 Del �ۑ�#48(�ύX#164)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN NVL(xoha.sum_capacity,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
             END                                      -- 25:�d�ʁ^�e��
            ,xoha.mixed_no                            -- 26:���ڌ��˗�No
            ,xoha.collected_pallet_qty                -- 27:��گĉ������
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:�^���敪
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:���׎��Ԏw��From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:���׎��Ԏw��To
            ,xoha.cust_po_number                      -- 31:�ڋq�����ԍ�
            ,xoha.shipping_instructions               -- 32:�E�v
            ,xoha.pallet_sum_quantity                 -- 33:��گĎg�p�����i�o�j
            ,NULL                                     -- 34:��گĎg�p�����i���j
            ,xoha.instruction_dept                    -- 35:�񍐕���
            ,xic.prod_class_code                      -- 36:���i�敪
            ,xic.item_class_code                      -- 37:�i�ڋ敪
            ,xim.item_no                              -- 38:�i�ڃR�[�h
            ,xim.item_id                              -- 39:�i��ID
            ,xim.item_name                            -- 40:�i�ږ�
            ,xim.item_um                              -- 41:�P��
            ,xim.conv_unit                            -- 42:���o�Ɋ��Z�P��
            ,xola.quantity                            -- 43:����
            ,xim.num_of_cases                         -- 44:�P�[�X����
            ,xim.lot_ctl                              -- 45:���b�g�g�p
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xoha.notif_date                          --   :�m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
            ,gn_request_id                            --   :�v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
          ,xxcmn_item_locations_v     xil       -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_carriers2_v          xc        -- �^���Ǝҏ��VIEW2
          --,xxcmn_party_sites2_v       xps       -- �p�[�e�B�T�C�g���VIEW2�i�z����j-- 2008/09/10 �Q��View�ύX Del
          ,xxcmn_cust_acct_sites2_v   xcas      -- �ڋq�T�C�g���VIEW2                -- 2008/09/10 �Q��View�ύX Add
          --,xxcmn_parties2_v           xp        -- �p�[�e�B���VIEW2�i���_�j        -- 2008/09/10 �Q��View�ύX Del
          ,xxcmn_cust_accounts2_v     xca       -- �ڋq���VIEW2                      -- 2008/09/10 �Q��View�ύX Add
          ,xxwsh_carriers_schedule    xcs       -- �z�Ԕz���v��A�h�I��
          ,xxcmn_lookup_values2_v     xlv       -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM�i�ڏ��VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM�i�ڃJ�e�S������VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM�i�ڃJ�e�S������VIEW5
          ,(SELECT distinct xtc.concurrent_id
              FROM xxwsh_tightening_control xtc
             WHERE xtc.tightening_date BETWEEN gd_date_from
                                           AND gd_date_to
           ) xtci
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �i��
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- �󒍖���
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
      AND   xola.delete_flag     = gc_yes_no_n    -- �폜�t���O = N
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
      ----------------------------------------------------------------------------------------------
      -- �z���z�Ԍv��
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- �z����
      --AND   gd_effective_date  BETWEEN xp.start_date_active                         -- 2008/09/10 �Q��View�ύX Del
      --                         AND     NVL( xp.end_date_active, gd_effective_date ) -- 2008/09/10 �Q��View�ύX Del
      AND   gd_effective_date  BETWEEN xca.start_date_active                          -- 2008/09/10 �Q��View�ύX Add
                               AND     NVL( xca.end_date_active, gd_effective_date )  -- 2008/09/10 �Q��View�ύX Add
      -- 2008/09/10 �Q��View�ύX Del Start -------------------------------
      --AND   xps.base_code      = xp.party_number
      --AND   gd_effective_date  BETWEEN xps.start_date_active
      --                         AND     NVL( xps.end_date_active, gd_effective_date )
      --AND   xoha.deliver_to_id = xps.party_site_id
      -- 2008/09/10 �Q��View�ύX Del End --------------------------------
      -- 2008/09/10 �Q��View�ύX Add Start --------------------------------
      AND   xcas.base_code      = xca.party_number
      AND   gd_effective_date  BETWEEN xcas.start_date_active
                               AND     NVL( xcas.end_date_active, gd_effective_date )
      AND   xoha.deliver_to_id = xcas.party_site_id
      -- 2008/09/10 �Q��View�ύX Add End --------------------------------
      ----------------------------------------------------------------------------------------------
      -- �^���Ǝ�
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/***** EOS����ɂ������폜
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS�Ǝ�
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      AND   otta.attribute1    = gc_sp_class_ship     -- �o�׈˗�
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      AND   xoha.latest_external_flag = gc_yes_no_y             -- �ŐV
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
      AND   xoha.prod_class           = gv_item_div_security    -- ���i�敪�i�Z�L�����e�B�j
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
      AND   xoha.req_status           IN( gc_req_status_syu_3   -- ���ߍ�
                                         ,gc_req_status_syu_5 ) -- ���
-- M.HOKKANJI Ver1.9 START
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND  ((gr_param.fix_class = gc_fix_class_y
--              AND EXISTS ( SELECT xic.concurrent_id
--                             FROM xxwsh_tightening_control xic
--                            WHERE xic.concurrent_id = xoha.tightening_program_id
--                              AND xic.tightening_date BETWEEN gd_date_from
--                                                          AND gd_date_to
--                         )
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
      AND   xoha.tightening_program_id = xtci.concurrent_id
-- 2008/09/01 v1.16 update Y.Yamamoto end
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- �x���f�[�^�r�p�k
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:���הԍ�
            ,xola.order_line_id                       -- 02:����ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:���׍폜�t���O
            ,xoha.req_status                          -- 04:�X�e�[�^�X
            ,xoha.notif_status                        -- 05:�ʒm�X�e�[�^�X
            ,xoha.prev_notif_status                   -- 06:�O��ʒm�X�e�[�^�X
            ,CASE
               WHEN xoha.req_status = gc_req_status_shi_5 THEN gc_data_type_shi_can
               ELSE gc_data_type_shi_ins
             END                                      -- 07:�f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
            ,NULL                                     -- XX:EOS����i���ɑq�Ɂj
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
            ,xil.eos_detination                       -- 08:EOS����i�o�ɑq�Ɂj
            ,xc.eos_detination                        -- 09:EOS����i�^���Ǝҁj
            ,xoha.delivery_no                         -- 10:�z��No
            ,xoha.request_no                          -- 11:�˗�No
            ,NULL                                     -- 12:���_�R�[�h
            ,NULL                                     -- 13:�Ǌ����_����
            ,xil.segment1                             -- 14:�o�ɑq�ɃR�[�h
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:�o�ɑq�ɖ���
            ,NULL                                     -- 16:���ɑq�ɃR�[�h
            ,NULL                                     -- 17:���ɑq�ɖ���
            ,xc.party_number                          -- 18:�^���Ǝ҃R�[�h
            ,xc.party_name                            -- 19:�^���ƎҖ�
            ,xvs.vendor_site_code                     -- 20:�z����R�[�h
            ,xvs.vendor_site_name                     -- 21:�z���於
            ,xoha.schedule_ship_date                  -- 22:����
            ,xoha.schedule_arrival_date               -- 23:����
            ,xlv.lookup_code                          -- 24:�z���敪
            ,CASE
               --2008/08/12 Start �ۑ�#48(�ύX#164) ----------------------------------------------
               --WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN xoha.sum_weight
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN xoha.sum_capacity
               WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN NVL(xoha.sum_weight,0)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN NVL(xoha.sum_capacity,0)
               --2008/08/12 End �ۑ�#48(�ύX#164) ------------------------------------------------
             END                                      -- 25:�d�ʁ^�e��
            ,xoha.mixed_no                            -- 26:���ڌ��˗�No
            ,xoha.collected_pallet_qty                -- 27:��گĉ������
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:�^���敪
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:���׎��Ԏw��From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:���׎��Ԏw��To
            ,xoha.cust_po_number                      -- 31:�ڋq�����ԍ�
            ,xoha.shipping_instructions               -- 32:�E�v
            ,xoha.pallet_sum_quantity                 -- 33:��گĎg�p�����i�o�j
            ,NULL                                     -- 34:��گĎg�p�����i���j
            ,xoha.instruction_dept                    -- 35:�񍐕���
            ,xic.prod_class_code                      -- 36:���i�敪
            ,xic.item_class_code                      -- 37:�i�ڋ敪
            ,xim.item_no                              -- 38:�i�ڃR�[�h
            ,xim.item_id                              -- 39:�i��ID
            ,xim.item_name                            -- 40:�i�ږ�
            ,xim.item_um                              -- 41:�P��
            ,xim.conv_unit                            -- 42:���o�Ɋ��Z�P��
            ,xola.quantity                            -- 43:����
            ,xim.num_of_cases                         -- 44:�P�[�X����
            ,xim.lot_ctl                              -- 45:���b�g�g�p
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xoha.notif_date                          --   :�m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
            ,gn_request_id                            --   :�v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
          ,xxcmn_item_locations_v     xil       -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_carriers2_v          xc        -- �^���Ǝҏ��VIEW2
          ,xxcmn_vendor_sites_v       xvs       -- �d����T�C�g���VIEW2
          ,xxwsh_carriers_schedule    xcs       -- �z�Ԕz���v��A�h�I��
          ,xxcmn_lookup_values2_v     xlv       -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM�i�ڏ��VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM�i�ڃJ�e�S������VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM�i�ڃJ�e�S������VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �i��
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- �󒍖���
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
      AND   xola.delete_flag     = gc_yes_no_n      -- �폜�t���O = N
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
      ----------------------------------------------------------------------------------------------
      -- �z���z�Ԍv��
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- �z����
      AND   gd_effective_date   BETWEEN xvs.start_date_active
                                AND     NVL( xvs.end_date_active, gd_effective_date )
      AND   xoha.vendor_site_id = xvs.vendor_site_id
      ----------------------------------------------------------------------------------------------
      -- �^���Ǝ�
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/***** EOS����ɂ������폜
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS�Ǝ�
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      AND   otta.attribute1    = gc_sp_class_prov     -- �x���˗�
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      AND   xoha.latest_external_flag = gc_yes_no_y             -- �ŐV
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
      AND   xoha.prod_class           = gv_item_div_security    -- ���i�敪�i�Z�L�����e�B�j
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
      AND   xoha.req_status           IN( gc_req_status_shi_3   -- ��̍�
                                         ,gc_req_status_shi_5 ) -- ���
--
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
      ----------------------------------------------------------------------------------------------
      -- �o�ɓ�From To
      AND   xoha.schedule_ship_date BETWEEN gd_ship_date_from AND gd_ship_date_to
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
--
-- M.HOKKANJI Ver1.9 START
-- 2008/09/01 v1.16 delete Y.Yamamoto start
      -- �p�����[�^���m��̏ꍇ�̂ݓ��t���Q��
--      AND  ((gr_param.fix_class = gc_fix_class_y
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
-- 2008/09/01 v1.16 delete Y.Yamamoto end
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- �ړ��f�[�^�r�p�k
      -- ===========================================================================================
      SELECT xmril.line_number                        -- 01:���הԍ�
            ,xmril.mov_line_id                        -- 02:����ID
            ,CASE
               WHEN xmril.delete_flg = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:���׍폜�t���O
            ,xmrih.status                             -- 04:�X�e�[�^�X
            ,xmrih.notif_status                       -- 05:�ʒm�X�e�[�^�X
            ,xmrih.prev_notif_status                  -- 06:�O��ʒm�X�e�[�^�X
            ,CASE
               WHEN xmrih.status = gc_req_status_syu_5 THEN gc_data_type_mov_can
               ELSE gc_data_type_mov_ins
             END                                      -- 07:�f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
            ,xil2.eos_detination                      -- XX:EOS����i���ɑq�Ɂj
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
            ,xil1.eos_detination                      -- 08:EOS����i�o�ɑq�Ɂj
            ,xc.eos_detination                        -- 09:EOS����i�^���Ǝҁj
            ,xmrih.delivery_no                        -- 10:�z��No
            ,xmrih.mov_num                            -- 11:�˗�No
            ,NULL                                     -- 12:���_�R�[�h
            ,NULL                                     -- 13:�Ǌ����_����
            ,xil1.segment1                            -- 14:�o�ɑq�ɃR�[�h
            ,SUBSTRB( xil1.description, 1, 20 )       -- 15:�o�ɑq�ɖ���
            ,xil2.segment1                            -- 16:���ɑq�ɃR�[�h
            ,SUBSTRB( xil2.description, 1, 20 )       -- 17:���ɑq�ɖ���
            ,xc.party_number                          -- 18:�^���Ǝ҃R�[�h
            ,xc.party_name                            -- 19:�^���ƎҖ�
            ,NULL                                     -- 20:�z����R�[�h
            ,NULL                                     -- 21:�z���於
            ,xmrih.schedule_ship_date                 -- 22:����
            ,xmrih.schedule_arrival_date              -- 23:����
            ,xlv.lookup_code                          -- 24:�z���敪
            ,CASE
-- M.HOKKANJI Ver1.2 START
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6               = gc_small_method_y THEN xmrih.sum_weight      --2008/08/12 Del �ۑ�#48(�ύX#164)
               AND  xlv.attribute6               = gc_small_method_y THEN NVL(xmrih.sum_weight,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xmrih.sum_weight,0)
                                                                    + NVL(xmrih.sum_pallet_weight,0)
                                                                    
               --WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity      --2008/08/12 Del �ۑ�#48(�ύX#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN NVL(xmrih.sum_capacity,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
/*
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6               = gc_wc_class_j THEN xmrih.sum_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6              <> gc_wc_class_j THEN xmrih.sum_weight
                                                                    + xmrih.sum_pallet_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity
*/
-- M.HOKKANJI Ver1.2 END
             END                                      -- 25:�d�ʁ^�e��
            ,NULL                                     -- 26:���ڌ��˗�No
            ,xmrih.collected_pallet_qty               -- 27:��گĉ������
            ,CASE
               WHEN xmrih.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END                                                -- 28:�^���敪
            ,NVL( xmrih.arrival_time_from, gc_time_default )    -- 29:���׎��Ԏw��From
            ,NVL( xmrih.arrival_time_to  , gc_time_default )    -- 30:���׎��Ԏw��To
            ,NULL                                     -- 31:�ڋq�����ԍ�
            ,xmrih.description                        -- 32:�E�v
            --,xmrih.out_pallet_qty                     -- 33:��گĎg�p�����i�o�j -- 2008/09/09 TE080_600�w�E#30 Del
            --,xmrih.in_pallet_qty                      -- 34:��گĎg�p�����i���j -- 2008/09/09 TE080_600�w�E#30 Del
            ,xmrih.pallet_sum_quantity                  -- 33:��گĎg�p�����i�o�j -- 2008/09/09 TE080_600�w�E#30 Add
            ,xmrih.pallet_sum_quantity                  -- 34:��گĎg�p�����i���j -- 2008/09/09 TE080_600�w�E#30 Add
            ,xmrih.instruction_post_code              -- 35:�񍐕���
            ,xic.prod_class_code                      -- 36:���i�敪
            ,xic.item_class_code                      -- 37:�i�ڋ敪
            ,xim.item_no                              -- 38:�i�ڃR�[�h
            ,xim.item_id                              -- 39:�i��ID
            ,xim.item_name                            -- 40:�i�ږ�
            ,xim.item_um                              -- 41:�P��
            ,xim.conv_unit                            -- 42:���o�Ɋ��Z�P��
            ,xmril.instruct_qty                       -- 43:����
            ,xim.num_of_cases                         -- 44:�P�[�X����
            ,xim.lot_ctl                              -- 45:���b�g�g�p
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xmrih.notif_date                         --   :�m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
            ,gn_request_id                            --   :�v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FROM xxinv_mov_req_instr_headers    xmrih     -- �ړ��˗��w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril     -- �ړ��˗��w�����׃A�h�I��
          ,xxcmn_item_locations_v         xil1      -- OPM�ۊǏꏊ���VIEW�i�z�����j
          ,xxcmn_item_locations_v         xil2      -- OPM�ۊǏꏊ���VIEW�i�z����j
          ,xxcmn_carriers2_v              xc        -- �^���Ǝҏ��VIEW2
          ,xxwsh_carriers_schedule        xcs       -- �z�Ԕz���v��A�h�I��
          ,xxcmn_lookup_values2_v         xlv       -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_item_mst2_v              xim       -- OPM�i�ڏ��VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM�i�ڃJ�e�S������VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM�i�ڃJ�e�S������VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �i��
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xmril.item_id           = xim.item_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w������
      AND   xmrih.mov_hdr_id = xmril.mov_hdr_id
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
      AND   xmril.delete_flg = gc_yes_no_n          -- �폜�t���O = N
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
      ----------------------------------------------------------------------------------------------
      -- �z���z�Ԍv��
-- M.HOKKANJI Ver1.2 START
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date)
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xmrih.delivery_no = xcs.delivery_no(+)
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xmrih.delivery_no = xcs.delivery_no
*/
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- �^���Ǝ�
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xmrih.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
/***
      -- �ۊǏꏊ�i�z����j
      AND   xil2.eos_control_type  = gc_manage_eos_y    -- EOS�Ǝ�
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ�i�z�����j
      AND   xil1.eos_control_type  = gc_manage_eos_y    -- EOS�Ǝ�
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
***/
      -- �ۊǏꏊ�i�z����j
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ�i�z�����j
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/***** EOS����ɂ������폜
      AND   (xil1.eos_control_type  = gc_manage_eos_y   -- EOS�Ǝҁi�z����j
          OR xil2.eos_control_type  = gc_manage_eos_y)  -- EOS�Ǝҁi�z�����j
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
      -- �ړ��˗��w���w�b�_
      AND   xmrih.mov_type    = gc_mov_type_y           -- �ϑ�����
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
      AND   xmrih.item_class  = gv_item_div_security    -- ���i�敪�i�Z�L�����e�B�j
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
      AND   xmrih.status      IN( gc_mov_status_cmp     -- �˗���
                                 ,gc_mov_status_adj     -- ������
                                 ,gc_mov_status_ccl )   -- ���
      ---- �p�����[�^���u���сv�̏ꍇ�̂�
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, gd_date_from
--                                      , gc_fix_class_k, xmrih.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
      AND   gd_date_from BETWEEN gd_date_from
                             AND gd_date_to
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
      ----------------------------------------------------------------------------------------------
      -- �o�ɓ�From To
      AND   xmrih.schedule_ship_date BETWEEN gd_ship_date_from AND gd_ship_date_to
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
-- 2008/09/01 v1.16 update Y.Yamamoto end
      ;
    -- ====================================================
    -- �\��m��敪���u�m��v�̏ꍇ
    -- ====================================================
    ELSIF ( gr_param.fix_class = gc_fix_class_k ) THEN
    INSERT INTO xxwsh_stock_delivery_info_tmp2
      -- ===========================================================================================
      -- �o�׃f�[�^�r�p�k
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:���הԍ�
            ,xola.order_line_id                       -- 02:����ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:���׍폜�t���O
            ,xoha.req_status                          -- 04:�X�e�[�^�X
            ,xoha.notif_status                        -- 05:�ʒm�X�e�[�^�X
            ,xoha.prev_notif_status                   -- 06:�O��ʒm�X�e�[�^�X
            ,CASE
               WHEN xoha.req_status = gc_req_status_syu_5 THEN gc_data_type_syu_can
               ELSE gc_data_type_syu_ins
             END                                      -- 07:�f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
            ,NULL                                     -- XX:EOS����i���ɑq�Ɂj
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
            ,xil.eos_detination                       -- 08:EOS����i�o�ɑq�Ɂj
            ,xc.eos_detination                        -- 09:EOS����i�^���Ǝҁj
            ,xoha.delivery_no                         -- 10:�z��No
            ,xoha.request_no                          -- 11:�˗�No
            --,xp.party_number                          -- 12:���_�R�[�h   -- 2008/09/10 �Q��View�ύX Del
            --,xp.party_name                            -- 13:�Ǌ����_���� -- 2008/09/10 �Q��View�ύX Del
            ,xca.party_number                          -- 12:���_�R�[�h    -- 2008/09/10 �Q��View�ύX Add
            ,xca.party_name                            -- 13:�Ǌ����_����  -- 2008/09/10 �Q��View�ύX Add
            ,xil.segment1                             -- 14:�o�ɑq�ɃR�[�h
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:�o�ɑq�ɖ���
            ,NULL                                     -- 16:���ɑq�ɃR�[�h
            ,NULL                                     -- 17:���ɑq�ɖ���
            ,xc.party_number                          -- 18:�^���Ǝ҃R�[�h
            ,xc.party_name                            -- 19:�^���ƎҖ�
            --,xps.party_site_number                    -- 20:�z����R�[�h -- 2008/09/10 �Q��View�ύX Del
            --,xps.party_site_full_name                 -- 21:�z���於     -- 2008/09/10 �Q��View�ύX Del
            ,xcas.party_site_number                   -- 20:�z����R�[�h   -- 2008/09/10 �Q��View�ύX Add
            ,xcas.party_site_full_name                -- 21:�z���於       -- 2008/09/10 �Q��View�ύX Add
            ,xoha.schedule_ship_date                  -- 22:����
            ,xoha.schedule_arrival_date               -- 23:����
            ,xlv.lookup_code                          -- 24:�z���敪
            ,CASE
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6              = gc_small_method_y THEN xoha.sum_weight      --2008/08/12 Del �ۑ�#48(�ύX#164)
               AND  xlv.attribute6              = gc_small_method_y THEN NVL(xoha.sum_weight,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
-- M.HOKKANJI Ver1.2 START
               WHEN xoha.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xoha.sum_weight,0)
                                                                      + NVL(xoha.sum_pallet_weight,0)
--               AND  xlv.attribute6             <> gc_small_method_y THEN xoha.sum_weight
--                                                                      + xoha.sum_pallet_weight
-- M.HOKKANJI Ver1.2 END
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN xoha.sum_capacity      --2008/08/12 Del �ۑ�#48(�ύX#164)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y     THEN NVL(xoha.sum_capacity,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
             END                                      -- 25:�d�ʁ^�e��
            ,xoha.mixed_no                            -- 26:���ڌ��˗�No
            ,xoha.collected_pallet_qty                -- 27:��گĉ������
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:�^���敪
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:���׎��Ԏw��From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:���׎��Ԏw��To
            ,xoha.cust_po_number                      -- 31:�ڋq�����ԍ�
            ,xoha.shipping_instructions               -- 32:�E�v
            ,xoha.pallet_sum_quantity                 -- 33:��گĎg�p�����i�o�j
            ,NULL                                     -- 34:��گĎg�p�����i���j
            ,xoha.instruction_dept                    -- 35:�񍐕���
            ,xic.prod_class_code                      -- 36:���i�敪
            ,xic.item_class_code                      -- 37:�i�ڋ敪
            ,xim.item_no                              -- 38:�i�ڃR�[�h
            ,xim.item_id                              -- 39:�i��ID
            ,xim.item_name                            -- 40:�i�ږ�
            ,xim.item_um                              -- 41:�P��
            ,xim.conv_unit                            -- 42:���o�Ɋ��Z�P��
            ,xola.quantity                            -- 43:����
            ,xim.num_of_cases                         -- 44:�P�[�X����
            ,xim.lot_ctl                              -- 45:���b�g�g�p
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xoha.notif_date                          --   :�m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
            ,gn_request_id                            --   :�v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
          ,xxcmn_item_locations_v     xil       -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_carriers2_v          xc        -- �^���Ǝҏ��VIEW2
          --,xxcmn_party_sites2_v       xps       -- �p�[�e�B�T�C�g���VIEW2�i�z����j-- 2008/09/10 �Q��View�ύX Del
          ,xxcmn_cust_acct_sites2_v   xcas      -- �ڋq�T�C�g���VIEW2                -- 2008/09/10 �Q��View�ύX Add
          --,xxcmn_parties2_v           xp        -- �p�[�e�B���VIEW2�i���_�j        -- 2008/09/10 �Q��View�ύX Del
          ,xxcmn_cust_accounts2_v     xca       -- �ڋq���VIEW2                      -- 2008/09/10 �Q��View�ύX Add
          ,xxwsh_carriers_schedule    xcs       -- �z�Ԕz���v��A�h�I��
          ,xxcmn_lookup_values2_v     xlv       -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM�i�ڏ��VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM�i�ڃJ�e�S������VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM�i�ڃJ�e�S������VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �i��
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- �󒍖���
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
      AND   xola.delete_flag     = gc_yes_no_n      -- �폜�t���O = N
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
      ----------------------------------------------------------------------------------------------
      -- �z���z�Ԍv��
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- �z����
      --AND   gd_effective_date  BETWEEN xp.start_date_active                         -- 2008/09/10 �Q��View�ύX Del
      --                         AND     NVL( xp.end_date_active, gd_effective_date ) -- 2008/09/10 �Q��View�ύX Del
      AND   gd_effective_date  BETWEEN xca.start_date_active                          -- 2008/09/10 �Q��View�ύX Add
                               AND     NVL( xca.end_date_active, gd_effective_date )  -- 2008/09/10 �Q��View�ύX Add
      -- 2008/09/10 �Q��View�ύX Del Start ----------------------------------
      --AND   xps.base_code      = xp.party_number
      --AND   gd_effective_date  BETWEEN xps.start_date_active
      --                         AND     NVL( xps.end_date_active, gd_effective_date )
      --AND   xoha.deliver_to_id = xps.party_site_id
      -- 2008/09/10 �Q��View�ύX Del End ----------------------------------
      -- 2008/09/10 �Q��View�ύX Add Start ----------------------------------
      AND   xcas.base_code      = xca.party_number
      AND   gd_effective_date  BETWEEN xcas.start_date_active
                               AND     NVL( xcas.end_date_active, gd_effective_date )
      AND   xoha.deliver_to_id = xcas.party_site_id
      -- 2008/09/10 �Q��View�ύX Add End ----------------------------------
      ----------------------------------------------------------------------------------------------
      -- �^���Ǝ�
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/***** EOS����ɂ������폜
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS�Ǝ�
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      AND   otta.attribute1    = gc_sp_class_ship     -- �o�׈˗�
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      AND   xoha.latest_external_flag = gc_yes_no_y             -- �ŐV
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
      AND   xoha.prod_class           = gv_item_div_security    -- ���i�敪�i�Z�L�����e�B�j
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
      AND   xoha.req_status           IN( gc_req_status_syu_3   -- ���ߍ�
                                         ,gc_req_status_syu_5 ) -- ���
-- M.HOKKANJI Ver1.9 START
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND  ((gr_param.fix_class = gc_fix_class_y
--              AND EXISTS ( SELECT xic.concurrent_id
--                             FROM xxwsh_tightening_control xic
--                            WHERE xic.concurrent_id = xoha.tightening_program_id
--                              AND xic.tightening_date BETWEEN gd_date_from
--                                                          AND gd_date_to
--                         )
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
      AND xoha.notif_date BETWEEN gd_date_from
                              AND gd_date_to
-- 2008/09/01 v1.16 update Y.Yamamoto end
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- �x���f�[�^�r�p�k
      -- ===========================================================================================
      SELECT xola.order_line_number                   -- 01:���הԍ�
            ,xola.order_line_id                       -- 02:����ID
            ,CASE
               WHEN xola.delete_flag = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:���׍폜�t���O
            ,xoha.req_status                          -- 04:�X�e�[�^�X
            ,xoha.notif_status                        -- 05:�ʒm�X�e�[�^�X
            ,xoha.prev_notif_status                   -- 06:�O��ʒm�X�e�[�^�X
            ,CASE
               WHEN xoha.req_status = gc_req_status_shi_5 THEN gc_data_type_shi_can
               ELSE gc_data_type_shi_ins
             END                                      -- 07:�f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
            ,NULL                                     -- XX:EOS����i���ɑq�Ɂj
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
            ,xil.eos_detination                       -- 08:EOS����i�o�ɑq�Ɂj
            ,xc.eos_detination                        -- 09:EOS����i�^���Ǝҁj
            ,xoha.delivery_no                         -- 10:�z��No
            ,xoha.request_no                          -- 11:�˗�No
            ,NULL                                     -- 12:���_�R�[�h
            ,NULL                                     -- 13:�Ǌ����_����
            ,xil.segment1                             -- 14:�o�ɑq�ɃR�[�h
            ,SUBSTRB( xil.description, 1, 20 )        -- 15:�o�ɑq�ɖ���
            ,NULL                                     -- 16:���ɑq�ɃR�[�h
            ,NULL                                     -- 17:���ɑq�ɖ���
            ,xc.party_number                          -- 18:�^���Ǝ҃R�[�h
            ,xc.party_name                            -- 19:�^���ƎҖ�
            ,xvs.vendor_site_code                     -- 20:�z����R�[�h
            ,xvs.vendor_site_name                     -- 21:�z���於
            ,xoha.schedule_ship_date                  -- 22:����
            ,xoha.schedule_arrival_date               -- 23:����
            ,xlv.lookup_code                          -- 24:�z���敪
            ,CASE
               --2008/08/12 Start �ۑ�#48(�ύX#164) ----------------------------------------------
               --WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN xoha.sum_weight
               --WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN xoha.sum_capacity
               WHEN xoha.weight_capacity_class  = gc_wc_class_j   THEN NVL(xoha.sum_weight,0)
               WHEN xoha.weight_capacity_class  = gc_wc_class_y   THEN NVL(xoha.sum_capacity,0)
               --2008/08/12 End �ۑ�#48(�ύX#164) ------------------------------------------------
             END                                      -- 25:�d�ʁ^�e��
            ,xoha.mixed_no                            -- 26:���ڌ��˗�No
            ,xoha.collected_pallet_qty                -- 27:��گĉ������
            ,CASE
               WHEN xoha.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END freight_charge_class                         -- 28:�^���敪
            ,NVL( xoha.arrival_time_from, gc_time_default )   -- 29:���׎��Ԏw��From
            ,NVL( xoha.arrival_time_to  , gc_time_default )   -- 30:���׎��Ԏw��To
            ,xoha.cust_po_number                      -- 31:�ڋq�����ԍ�
            ,xoha.shipping_instructions               -- 32:�E�v
            ,xoha.pallet_sum_quantity                 -- 33:��گĎg�p�����i�o�j
            ,NULL                                     -- 34:��گĎg�p�����i���j
            ,xoha.instruction_dept                    -- 35:�񍐕���
            ,xic.prod_class_code                      -- 36:���i�敪
            ,xic.item_class_code                      -- 37:�i�ڋ敪
            ,xim.item_no                              -- 38:�i�ڃR�[�h
            ,xim.item_id                              -- 39:�i��ID
            ,xim.item_name                            -- 40:�i�ږ�
            ,xim.item_um                              -- 41:�P��
            ,xim.conv_unit                            -- 42:���o�Ɋ��Z�P��
            ,xola.quantity                            -- 43:����
            ,xim.num_of_cases                         -- 44:�P�[�X����
            ,xim.lot_ctl                              -- 45:���b�g�g�p
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xoha.notif_date                          --   :�m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
            ,gn_request_id                            --   :�v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
          ,xxcmn_item_locations_v     xil       -- OPM�ۊǏꏊ���VIEW
          ,xxcmn_carriers2_v          xc        -- �^���Ǝҏ��VIEW2
          ,xxcmn_vendor_sites_v       xvs       -- �d����T�C�g���VIEW2
          ,xxwsh_carriers_schedule    xcs       -- �z�Ԕz���v��A�h�I��
          ,xxcmn_lookup_values2_v     xlv       -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_item_mst2_v          xim       -- OPM�i�ڏ��VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM�i�ڃJ�e�S������VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM�i�ڃJ�e�S������VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �i��
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xola.shipping_item_code = xim.item_no
      ----------------------------------------------------------------------------------------------
      -- �󒍖���
      AND   xoha.order_header_id = xola.order_header_id
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
      AND   xola.delete_flag     = gc_yes_no_n      -- �폜�t���O = N
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
      ----------------------------------------------------------------------------------------------
      -- �z���z�Ԍv��
-- M.HOKKANJI Ver1.2 START
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xoha.delivery_no  = xcs.delivery_no
*/
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date )
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xoha.delivery_no  = xcs.delivery_no(+)
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- �z����
      AND   gd_effective_date   BETWEEN xvs.start_date_active
                                AND     NVL( xvs.end_date_active, gd_effective_date )
      AND   xoha.vendor_site_id = xvs.vendor_site_id
      ----------------------------------------------------------------------------------------------
      -- �^���Ǝ�
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xoha.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/***** EOS����ɂ������폜
      AND   xil.eos_control_type = gc_manage_eos_y    -- EOS�Ǝ�
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
      AND   xoha.deliver_from_id = xil.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      AND   otta.attribute1    = gc_sp_class_prov     -- �x���˗�
      AND   xoha.order_type_id = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      AND   xoha.latest_external_flag = gc_yes_no_y             -- �ŐV
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
      AND   xoha.prod_class           = gv_item_div_security    -- ���i�敪�i�Z�L�����e�B�j
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
      AND   xoha.req_status           IN( gc_req_status_shi_3   -- ��̍�
                                         ,gc_req_status_shi_5 ) -- ���
-- M.HOKKANJI Ver1.9 START
      -- �p�����[�^���m��̏ꍇ�̂ݓ��t���Q��
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND  ((gr_param.fix_class = gc_fix_class_y
--            ) OR (gr_param.fix_class = gc_fix_class_k
--              AND xoha.notif_date BETWEEN gd_date_from
--                                      AND gd_date_to))
      AND   xoha.notif_date BETWEEN gd_date_from
                                AND gd_date_to
-- 2008/09/01 v1.16 update Y.Yamamoto end
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, xoha.tightening_date
--                                      , gc_fix_class_k, xoha.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
-- M.HOKKANJI Ver1.9 END
      UNION ALL
      -- ===========================================================================================
      -- �ړ��f�[�^�r�p�k
      -- ===========================================================================================
      SELECT xmril.line_number                        -- 01:���הԍ�
            ,xmril.mov_line_id                        -- 02:����ID
            ,CASE
               WHEN xmril.delete_flg = gc_yes_no_y THEN gc_delete_flag_y
               ELSE gc_delete_flag_n
             END                                      -- 03:���׍폜�t���O
            ,xmrih.status                             -- 04:�X�e�[�^�X
            ,xmrih.notif_status                       -- 05:�ʒm�X�e�[�^�X
            ,xmrih.prev_notif_status                  -- 06:�O��ʒm�X�e�[�^�X
            ,CASE
               WHEN xmrih.status = gc_req_status_syu_5 THEN gc_data_type_mov_can
               ELSE gc_data_type_mov_ins
             END                                      -- 07:�f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
            ,xil2.eos_detination                      -- XX:EOS����i���ɑq�Ɂj
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
            ,xil1.eos_detination                      -- 08:EOS����i�o�ɑq�Ɂj
            ,xc.eos_detination                        -- 09:EOS����i�^���Ǝҁj
            ,xmrih.delivery_no                        -- 10:�z��No
            ,xmrih.mov_num                            -- 11:�˗�No
            ,NULL                                     -- 12:���_�R�[�h
            ,NULL                                     -- 13:�Ǌ����_����
            ,xil1.segment1                            -- 14:�o�ɑq�ɃR�[�h
            ,SUBSTRB( xil1.description, 1, 20 )       -- 15:�o�ɑq�ɖ���
            ,xil2.segment1                            -- 16:���ɑq�ɃR�[�h
            ,SUBSTRB( xil2.description, 1, 20 )       -- 17:���ɑq�ɖ���
            ,xc.party_number                          -- 18:�^���Ǝ҃R�[�h
            ,xc.party_name                            -- 19:�^���ƎҖ�
            ,NULL                                     -- 20:�z����R�[�h
            ,NULL                                     -- 21:�z���於
            ,xmrih.schedule_ship_date                 -- 22:����
            ,xmrih.schedule_arrival_date              -- 23:����
            ,xlv.lookup_code                          -- 24:�z���敪
            ,CASE
-- M.HOKKANJI Ver1.2 START
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               --AND  xlv.attribute6               = gc_small_method_y THEN xmrih.sum_weight      --2008/08/12 Del �ۑ�#48(�ύX#164)
               AND  xlv.attribute6               = gc_small_method_y THEN NVL(xmrih.sum_weight,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  NVL(xlv.attribute6,gc_small_method_n) <> gc_small_method_y THEN NVL(xmrih.sum_weight,0)
                                                                    + NVL(xmrih.sum_pallet_weight,0)
                                                                    
               --WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity      --2008/08/12 Del �ۑ�#48(�ύX#164)
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN NVL(xmrih.sum_capacity,0) --2008/08/12 Add �ۑ�#48(�ύX#164)
/*
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6               = gc_wc_class_j THEN xmrih.sum_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_j
               AND  xlv.attribute6              <> gc_wc_class_j THEN xmrih.sum_weight
                                                                    + xmrih.sum_pallet_weight
               WHEN xmrih.weight_capacity_class  = gc_wc_class_y THEN xmrih.sum_capacity
*/
-- M.HOKKANJI Ver1.2 END
             END                                      -- 25:�d�ʁ^�e��
            ,NULL                                     -- 26:���ڌ��˗�No
            ,xmrih.collected_pallet_qty               -- 27:��گĉ������
            ,CASE
               WHEN xmrih.freight_charge_class = gc_freight_class_y THEN gc_freight_class_ins_y
               ELSE gc_freight_class_ins_n
             END                                                -- 28:�^���敪
            ,NVL( xmrih.arrival_time_from, gc_time_default )    -- 29:���׎��Ԏw��From
            ,NVL( xmrih.arrival_time_to  , gc_time_default )    -- 30:���׎��Ԏw��To
            ,NULL                                     -- 31:�ڋq�����ԍ�
            ,xmrih.description                        -- 32:�E�v
            --,xmrih.out_pallet_qty                     -- 33:��گĎg�p�����i�o�j  -- 2008/09/09 TE080_600�w�E#30 Del
            --,xmrih.in_pallet_qty                      -- 34:��گĎg�p�����i���j  -- 2008/09/09 TE080_600�w�E#30 Del
            ,xmrih.pallet_sum_quantity                  -- 33:��گĎg�p�����i�o�j  -- 2008/09/09 TE080_600�w�E#30 Add
            ,xmrih.pallet_sum_quantity                  -- 34:��گĎg�p�����i���j  -- 2008/09/09 TE080_600�w�E#30 Add
            ,xmrih.instruction_post_code              -- 35:�񍐕���
            ,xic.prod_class_code                      -- 36:���i�敪
            ,xic.item_class_code                      -- 37:�i�ڋ敪
            ,xim.item_no                              -- 38:�i�ڃR�[�h
            ,xim.item_id                              -- 39:�i��ID
            ,xim.item_name                            -- 40:�i�ږ�
            ,xim.item_um                              -- 41:�P��
            ,xim.conv_unit                            -- 42:���o�Ɋ��Z�P��
            ,xmril.instruct_qty                       -- 43:����
            ,xim.num_of_cases                         -- 44:�P�[�X����
            ,xim.lot_ctl                              -- 45:���b�g�g�p
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xmrih.notif_date                         --   :�m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
            ,gn_request_id                            --   :�v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
      FROM xxinv_mov_req_instr_headers    xmrih     -- �ړ��˗��w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril     -- �ړ��˗��w�����׃A�h�I��
          ,xxcmn_item_locations_v         xil1      -- OPM�ۊǏꏊ���VIEW�i�z�����j
          ,xxcmn_item_locations_v         xil2      -- OPM�ۊǏꏊ���VIEW�i�z����j
          ,xxcmn_carriers2_v              xc        -- �^���Ǝҏ��VIEW2
          ,xxwsh_carriers_schedule        xcs       -- �z�Ԕz���v��A�h�I��
          ,xxcmn_lookup_values2_v         xlv       -- �N�C�b�N�R�[�h���VIEW2
          ,xxcmn_item_mst2_v              xim       -- OPM�i�ڏ��VIEW2
-- 2008/09/01 v1.16 update Y.Yamamoto start
--          ,xxcmn_item_categories4_v   xic       -- OPM�i�ڃJ�e�S������VIEW4
          ,xxcmn_item_categories5_v   xic       -- OPM�i�ڃJ�e�S������VIEW5
-- 2008/09/01 v1.16 update Y.Yamamoto end
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �i��
            xim.item_id             = xic.item_id
      AND   gd_effective_date       BETWEEN xim.start_date_active
                                    AND     NVL( xim.end_date_active, gd_effective_date )
      AND   xmril.item_id           = xim.item_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w������
      AND   xmrih.mov_hdr_id = xmril.mov_hdr_id
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
      AND   xmril.delete_flg = gc_yes_no_n        -- �폜�t���O = N
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
      ----------------------------------------------------------------------------------------------
      -- �z���z�Ԍv��
-- M.HOKKANJI Ver1.2 START
      AND   gd_effective_date BETWEEN NVL(xlv.start_date_active, gd_effective_date)
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag(+)  = gc_yes_no_y
      AND   xlv.lookup_type(+)   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code(+)
      AND   xmrih.delivery_no = xcs.delivery_no(+)
/*
      AND   gd_effective_date BETWEEN xlv.start_date_active
                              AND     NVL( xlv.end_date_active, gd_effective_date )
      AND   xlv.enabled_flag  = gc_yes_no_y
      AND   xlv.lookup_type   = gc_lookup_ship_method
      AND   xcs.delivery_type = xlv.lookup_code
      AND   xmrih.delivery_no = xcs.delivery_no
*/
-- M.HOKKANJI Ver1.2 END
      ----------------------------------------------------------------------------------------------
      -- �^���Ǝ�
      AND   gd_effective_date BETWEEN xc.start_date_active(+)
                              AND     NVL( xc.end_date_active(+), gd_effective_date )
      AND   xmrih.career_id    = xc.party_id(+)
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
/***
      -- �ۊǏꏊ�i�z����j
      AND   xil2.eos_control_type  = gc_manage_eos_y    -- EOS�Ǝ�
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ�i�z�����j
      AND   xil1.eos_control_type  = gc_manage_eos_y    -- EOS�Ǝ�
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
***/
      -- �ۊǏꏊ�i�z����j
      AND   xmrih.ship_to_locat_id = xil2.inventory_location_id
      ----------------------------------------------------------------------------------------------
      -- �ۊǏꏊ�i�z�����j
      AND   xmrih.shipped_locat_id = xil1.inventory_location_id
      ----------------------------------------------------------------------------------------------
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/***** EOS����ɂ������폜
      AND   (xil1.eos_control_type  = gc_manage_eos_y   -- EOS�Ǝҁi�z����j
          OR xil2.eos_control_type  = gc_manage_eos_y)  -- EOS�Ǝҁi�z�����j
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
      ----------------------------------------------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
      -- �ړ��˗��w���w�b�_
      AND   xmrih.mov_type    = gc_mov_type_y           -- �ϑ�����
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� START #####
      AND   xmrih.item_class  = gv_item_div_security    -- ���i�敪�i�Z�L�����e�B�j
-- ##### 20080612 Ver.1.7 ���i�Z�L�����e�B�Ή� END   #####
      AND   xmrih.status      IN( gc_mov_status_cmp     -- �˗���
                                 ,gc_mov_status_adj     -- ������
                                 ,gc_mov_status_ccl )   -- ���
      ---- �p�����[�^���u���сv�̏ꍇ�̂�
-- 2008/09/01 v1.16 update Y.Yamamoto start
--      AND   DECODE( gr_param.fix_class, gc_fix_class_y, gd_date_from
--                                      , gc_fix_class_k, xmrih.notif_date      )
--              BETWEEN gd_date_from AND gd_date_to
      AND   xmrih.notif_date BETWEEN gd_date_from
                                 AND gd_date_to
-- 2008/09/01 v1.16 update Y.Yamamoto end
      ;
    END IF;
-- 2008/09/01 v1.16 Y.Yamamoto End
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_ins_temp_table ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_main_data
   * Description      : ���C���f�[�^���o(E-04)
   ************************************************************************************************/
  PROCEDURE prc_get_main_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_main_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code       CONSTANT VARCHAR2(30) := 'APP-XXWSH-11856' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_sql            VARCHAR2(32000) ;
    lv_select         VARCHAR2(32000) ;
    lv_from           VARCHAR2(32000) ;
    lv_where          VARCHAR2(32000) ;
    lv_order          VARCHAR2(32000) ;
--
    -- ==================================================
    -- �q�d�e�J�[�\���錾
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    cu_ref      ref_cursor ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_no_data        EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�d�k�d�b�s��
    -- ====================================================
    lv_select := ' SELECT'
              ||    ' wsdit2.line_number'               -- ���הԍ�
              ||    ',wsdit2.line_delete_flag'          -- ���׍폜�t���O
              ||    ',wsdit2.prev_notif_status'         -- �O��ʒm�X�e�[�^�X
              ||    ',wsdit2.data_type'                 -- �f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
              ||    ',wsdit2.eos_shipped_to_locat'      -- EOS����i���ɑq�Ɂj
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
              ||    ',wsdit2.eos_shipped_locat'         -- EOS����i�o�ɑq�Ɂj
              ||    ',wsdit2.eos_freight_carrier'       -- EOS����i�^���Ǝҁj
              ||    ',wsdit2.delivery_no'               -- �z��No
              ||    ',wsdit2.request_no'                -- �˗�No
              ||    ',wsdit2.head_sales_branch'         -- ���_�R�[�h
              ||    ',wsdit2.head_sales_branch_name'    -- �Ǌ����_����
              ||    ',wsdit2.shipped_locat_code'        -- �o�ɑq�ɃR�[�h
              ||    ',wsdit2.shipped_locat_name'        -- �o�ɑq�ɖ���
              ||    ',wsdit2.ship_to_locat_code'        -- ���ɑq�ɃR�[�h
              ||    ',wsdit2.ship_to_locat_name'        -- ���ɑq�ɖ���
              ||    ',wsdit2.freight_carrier_code'      -- �^���Ǝ҃R�[�h
              ||    ',wsdit2.freight_carrier_name'      -- �^���ƎҖ�
              ||    ',wsdit2.deliver_to'                -- �z����R�[�h
              ||    ',wsdit2.deliver_to_name'           -- �z���於
              ||    ',wsdit2.schedule_ship_date'        -- ����
              ||    ',wsdit2.schedule_arrival_date'     -- ����
              ||    ',wsdit2.shipping_method_code'      -- �z���敪
              ||    ',wsdit2.weight'                    -- �d��/�e��
              ||    ',wsdit2.mixed_no'                  -- ���ڌ��˗���
              ||    ',wsdit2.collected_pallet_qty'      -- �p���b�g�������
              ||    ',wsdit2.freight_charge_class'      -- �^���敪
              ||    ',wsdit2.arrival_time_from'         -- ���׎��Ԏw��(FROM)
              ||    ',wsdit2.arrival_time_to'           -- ���׎��Ԏw��(TO)
              ||    ',wsdit2.cust_po_number'            -- �ڋq�����ԍ�
              ||    ',wsdit2.description'               -- �E�v
              ||    ',wsdit2.pallet_sum_quantity_out'   -- �p���b�g�g�p�����i�o�j
              ||    ',wsdit2.pallet_sum_quantity_in'    -- �p���b�g�g�p�����i���j
              ||    ',wsdit2.report_dept'               -- �񍐕���
              ||    ',wsdit2.prod_class'                -- ���i�敪
              ||    ',wsdit2.item_class'                -- �i�ڋ敪
              ||    ',wsdit2.item_code'                 -- �i�ڃR�[�h
              ||    ',wsdit2.item_name'                 -- �i�ږ�
              ||    ',wsdit2.item_uom_code'             -- �P��
              ||    ',wsdit2.conv_unit'                 -- ���o�Ɋ��Z�P��
              ||    ',wsdit2.item_quantity'             -- ����
              ||    ',wsdit2.case_quantity'             -- �P�[�X����
              ||    ',wsdit2.lot_class'                 -- ���b�g�Ǘ��敪
              ||    ',wsdit2.line_id'                   -- ����ID
              ||    ',wsdit2.item_id'                   -- �i��ID
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
              ||    ',wsdit2.notif_date'                -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
              ||    ',imld.mov_lot_dtl_id'              -- ���b�g�ڍ�ID
              ;
    -- ====================================================
    -- �e�q�n�l��
    -- ====================================================
    lv_from := ' FROM xxwsh_stock_delivery_info_tmp2 wsdit2, ' 
-- ##### 20080627 Ver.1.12 ST��QNo390 START #####
/*****
                   || 'xxinv_mov_lot_details imld';
*****/
             || ' ( SELECT   mov_lot_dtl_id as mov_lot_dtl_id '
             || '          , mov_line_id    as mov_line_id '
             || '   FROM   xxinv_mov_lot_details '
             || '   WHERE  document_type_code     IN ( '
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
-- ##### 20081023 Ver.1.25 ���R�[�h�^�C�v�w���̂ݑΉ� START #####
             || '   AND    record_type_code = ' || gc_rec_type_inst
-- ##### 20081023 Ver.1.25 ���R�[�h�^�C�v�w���̂ݑΉ� END   #####
             || ' ) imld '
              ;
-- ##### 20080627 Ver.1.12 ST��QNo390 END   #####
--
    -- ====================================================
    -- �v�g�d�q�d��
    -- ====================================================
    -------------------------------------------------------
    -- �\��m��敪���u�\��v�̏ꍇ
    -------------------------------------------------------
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
      lv_where := ' WHERE '
          || ' ('
            || ' wsdit2.data_type IN( ''' || gc_data_type_syu_ins || ''''
                                 || ',''' || gc_data_type_shi_ins || ''''
                                 || ',''' || gc_data_type_mov_ins || ''' )'
          || ' )'
          || ' AND'
          || ' ('
            || ' ('
            || '     wsdit2.notif_status      = ''' || gc_notif_status_n || ''''  -- ���ʒm
            || ' AND wsdit2.prev_notif_status IS NULL'                            -- �m�t�k�k
            || ' )'
            || ' OR'
            || ' ('
            || '     wsdit2.notif_status      = ''' || gc_notif_status_r || ''''  -- �Ēʒm
            || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_c || ''''  -- �m��ʒm
            || ' )'
          || ' )'
          ;
--
    -------------------------------------------------------
    -- �\��m��敪���u�m��v�̏ꍇ
    -------------------------------------------------------
    ELSIF ( gr_param.fix_class = gc_fix_class_k ) THEN
      lv_where := ' WHERE '
          || ' (('
            || ' ( wsdit2.data_type IN( ''' || gc_data_type_syu_ins || ''''
                                   || ',''' || gc_data_type_shi_ins || ''''
                                   || ',''' || gc_data_type_mov_ins || ''')'
            || ' AND wsdit2.notif_status      = ''' || gc_notif_status_c || ''''  -- �m��ʒm��
            || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_n || ''')' -- ���ʒm
            || ' AND  NOT EXISTS'
                      || '( SELECT 1'
                      || '  FROM xxwsh_notif_delivery_info xndi'
-- 2008/09/01 v1.16 update Y.Yamamoto start
--                      || '  WHERE xndi.request_no = wsdit2.request_no )'
                      || '  WHERE xndi.request_no = wsdit2.request_no '
                      || '  AND   rownum <= 1 )'
-- 2008/09/01 v1.16 update Y.Yamamoto end
          || ' )'
          || ' OR'
          || ' (   wsdit2.notif_status      = ''' || gc_notif_status_c || ''''  -- �m��ʒm��
          || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_r || ''''  -- �Ēʒm�v
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
--          || ' ))'
          || ' )'
              -- �g�����U�N�V�����̊m��ʒm���{�������A�ʒm�ϓ��o�ɔz���v������ȑO�̏ꍇ�͏��O
              || ' AND  NOT EXISTS'
                        || '( SELECT 1'
                        || '  FROM xxwsh_notif_delivery_info xndi'
                        || '  WHERE xndi.request_no  = wsdit2.request_no '
                        || '  AND   xndi.notif_date >= wsdit2.notif_date '
                        || '  AND   rownum <= 1 )'
          || ' )'
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
          ;
--
    END IF ;
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
    -------------------------------------------------------
    -- EOS��������i���ɁE�o�ɁE�^���Ǝ҂�EOS���悢���ꂩ���ݒ肳��Ă�����j
    -------------------------------------------------------
    lv_where := lv_where
            || ' AND ( wsdit2.eos_shipped_to_locat IS NOT NULL   '  -- EOS����i���ɑq�Ɂj
            || '    OR wsdit2.eos_shipped_locat    IS NOT NULL   '  -- EOS����i�o�ɑq�Ɂj
            || '    OR wsdit2.eos_freight_carrier  IS NOT NULL ) '  -- EOS����i�^���Ǝҁj
            ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
--
    -------------------------------------------------------
    -- �ړ����b�g�ڍׂƌ���
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.line_id = imld.mov_line_id (+) '
-- ##### 20080627 Ver.1.12 ST��QNo390 START #####
/*****
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
             || ' AND imld.document_type_code IN ('
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
*****/
-- ##### 20080627 Ver.1.12 ST��QNo390 END #####
             ;
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
    -------------------------------------------------------
    -- ���ʂ�0�ȏ�̖��ׂ��Ώ�
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.item_quantity > 0 '
              ;
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
--
    -------------------------------------------------------
    -- �p�����[�^�D����
    -------------------------------------------------------
-- 2008/07/16 Add ��
    lv_where := lv_where
             || ' AND ((wsdit2.report_dept = ''' || gr_param.dept_code_01 || ''')';
--
    IF (gr_param.dept_code_02 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_02 || ''')';
    END IF;
    IF (gr_param.dept_code_03 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_03 || ''')';
    END IF;
    IF (gr_param.dept_code_04 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_04 || ''')';
    END IF;
    IF (gr_param.dept_code_05 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_05 || ''')';
    END IF;
    IF (gr_param.dept_code_06 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_06 || ''')';
    END IF;
    IF (gr_param.dept_code_07 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_07 || ''')';
    END IF;
    IF (gr_param.dept_code_08 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_08 || ''')';
    END IF;
    IF (gr_param.dept_code_09 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_09 || ''')';
    END IF;
    IF (gr_param.dept_code_10 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_10 || ''')';
    END IF;
--
    lv_where := lv_where || ')';
-- 2008/07/16 Add ��
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    -------------------------------------------------------
    -- �v��ID
    -------------------------------------------------------
    lv_where := lv_where || ' AND wsdit2.target_request_id = ' || TO_CHAR(gn_request_id) || ' ' ;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
    -- ====================================================
    -- �n�q�c�d�q �a�x��
    -- ====================================================
    lv_order  := ' ORDER BY '
              || '   wsdit2.data_type'
              || '  ,wsdit2.request_no'
              || '  ,wsdit2.line_number'
              ;
--
    -- ====================================================
    -- �r�p�k������
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_order ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    OPEN cu_ref FOR lv_sql ;
    FETCH cu_ref BULK COLLECT INTO gt_main_data ;
    CLOSE cu_ref ;
--
    IF ( gt_main_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- �Ώۃf�[�^�Ȃ�
    -- =============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_get_main_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
--   ����f�[�^�擾���� �ǉ�
--     ���C���f�[�^���o�����ɂď����ɕύX���������ꍇ�͎������f�[�^���o�ɂ��ύX���K�v�ƂȂ�܂�
--
  /************************************************************************************************
   * Procedure Name   : prc_get_can_data
   * Description      : ����f�[�^���o
   ************************************************************************************************/
  PROCEDURE prc_get_can_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_can_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code       CONSTANT VARCHAR2(30) := 'APP-XXWSH-11856' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_sql            VARCHAR2(32000) ;
    lv_select         VARCHAR2(32000) ;
    lv_from           VARCHAR2(32000) ;
    lv_where          VARCHAR2(32000) ;
    lv_order          VARCHAR2(32000) ;
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� START #####
    lv_group          VARCHAR2(32000) ;
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� END   #####
--
    -- ==================================================
    -- �q�d�e�J�[�\���錾
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    cu_ref      ref_cursor ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_no_data        EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�d�k�d�b�s��
    -- ====================================================
    lv_select := ' SELECT '
              ||    ' wsdit2.request_no '   -- �˗�No
              ;
    -- ====================================================
    -- �e�q�n�l��
    -- ====================================================
    lv_from := ' FROM xxwsh_stock_delivery_info_tmp2 wsdit2, ' 
             || ' ( SELECT   mov_lot_dtl_id as mov_lot_dtl_id '
             || '          , mov_line_id    as mov_line_id '
             || '   FROM   xxinv_mov_lot_details '
             || '   WHERE  document_type_code     IN ( '
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
-- ##### 20081028 Ver.1.26 �Ή�����Ή� START #####
             || '   AND    record_type_code = '   || gc_rec_type_inst
-- ##### 20081028 Ver.1.26 �Ή�����Ή� END   #####
             || ' ) imld '
              ;
--
    -- ====================================================
    -- �v�g�d�q�d��
    -- ====================================================
    lv_where := ' WHERE '
        || ' (   wsdit2.notif_status      = ''' || gc_notif_status_c || ''''  -- �m��ʒm��
        || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_r || ''''  -- �Ēʒm�v
        || ' )'
        ;
--
    -------------------------------------------------------
    -- EOS��������i���ɁE�o�ɁE�^���Ǝ҂�EOS����S�Ă�NULL�̏ꍇ�j
    -------------------------------------------------------
    lv_where := lv_where
            || ' AND  wsdit2.eos_shipped_to_locat IS NULL  '  -- EOS����i���ɑq�Ɂj
            || ' AND  wsdit2.eos_shipped_locat    IS NULL  '  -- EOS����i�o�ɑq�Ɂj
            || ' AND  wsdit2.eos_freight_carrier  IS NULL  '  -- EOS����i�^���Ǝҁj
            ;
--
    -------------------------------------------------------
    -- �ړ����b�g�ڍׂƌ���
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.line_id = imld.mov_line_id (+) '
             ;
--
    -------------------------------------------------------
    -- �p�����[�^�D����
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND ((wsdit2.report_dept = ''' || gr_param.dept_code_01 || ''')';
--
    IF (gr_param.dept_code_02 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_02 || ''')';
    END IF;
    IF (gr_param.dept_code_03 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_03 || ''')';
    END IF;
    IF (gr_param.dept_code_04 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_04 || ''')';
    END IF;
    IF (gr_param.dept_code_05 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_05 || ''')';
    END IF;
    IF (gr_param.dept_code_06 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_06 || ''')';
    END IF;
    IF (gr_param.dept_code_07 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_07 || ''')';
    END IF;
    IF (gr_param.dept_code_08 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_08 || ''')';
    END IF;
    IF (gr_param.dept_code_09 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_09 || ''')';
    END IF;
    IF (gr_param.dept_code_10 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_10 || ''')';
    END IF;
--
    lv_where := lv_where || ')';
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    -------------------------------------------------------
    -- �v��ID
    -------------------------------------------------------
    lv_where := lv_where || ' AND wsdit2.target_request_id = ' || TO_CHAR(gn_request_id) || ' ' ;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� START #####
    -- ====================================================
    -- �f�q�n�t�o �a�x��
    -- ====================================================
    lv_group := ' GROUP BY '
            ||  ' wsdit2.request_no ';
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� END   #####
--
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� START #####
    -- ====================================================
    -- �n�q�c�d�q �a�x��
    -- ====================================================
--    lv_order  := ' ORDER BY '
--              || '   wsdit2.data_type'
--              || '  ,wsdit2.request_no'
--              || '  ,wsdit2.line_number'
--              ;
    lv_order  := ' ORDER BY '
              || '  wsdit2.request_no '
              ;
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� END   #####
--
    -- ====================================================
    -- �r�p�k������
    -- ====================================================
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� START #####
--    lv_sql := lv_select || lv_from || lv_where || lv_order ;
    lv_sql := lv_select || lv_from || lv_where || lv_group || lv_order ;
-- ##### 20081028 Ver.1.26 �Ή�����Ή��Ή� END   #####
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    OPEN cu_ref FOR lv_sql ;
    FETCH cu_ref BULK COLLECT INTO gt_can_data ;
    CLOSE cu_ref ;
--
    IF ( gt_can_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- �Ώۃf�[�^�Ȃ�
    -- =============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_get_can_data ;
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
--   �S�Ă̖��ׂ�0�̈˗��ɑ΂������f�[�^�擾���� �ǉ�
--     ���C���f�[�^���o�����ɂď����ɕύX���������ꍇ�͎������f�[�^���o�ɂ��ύX���K�v�ƂȂ�܂�
--
  /************************************************************************************************
   * Procedure Name   : prc_get_zero_can_data
   * Description      : �˗�����0�̎���f�[�^���o
   ************************************************************************************************/
  PROCEDURE prc_get_zero_can_data
    (
      ov_errbuf   OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode  OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg   OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_zero_can_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code       CONSTANT VARCHAR2(30) := 'APP-XXWSH-11856' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_main_sql       VARCHAR2(32000) ;
    lv_sql            VARCHAR2(32000) ;
    lv_select         VARCHAR2(32000) ;
    lv_from           VARCHAR2(32000) ;
    lv_where          VARCHAR2(32000) ;
    lv_order          VARCHAR2(32000) ;
    lv_group          VARCHAR2(32000) ;
--
    -- ==================================================
    -- �q�d�e�J�[�\���錾
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    cu_ref      ref_cursor ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_no_data        EXCEPTION ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �C�����C�� �r�d�k�d�b�s��
    -- ====================================================
    lv_select := ' SELECT'
              ||    '  wsdit2.request_no         AS request_no   '  -- �˗�No
              ||    ', SUM(wsdit2.item_quantity) AS sum_quantity '  -- ���ʁi�˗��̑����ʁj
              ;
    -- ====================================================
    -- �e�q�n�l��
    -- ====================================================
    lv_from := ' FROM xxwsh_stock_delivery_info_tmp2 wsdit2, ' 
             || ' ( SELECT   mov_lot_dtl_id as mov_lot_dtl_id '
             || '          , mov_line_id    as mov_line_id '
             || '   FROM   xxinv_mov_lot_details '
             || '   WHERE  document_type_code     IN ( '
             ||                 gc_doc_type_ship  || ',' 
             ||                 gc_doc_type_move  || ',' 
             ||                 gc_doc_type_prov  || ')'
             || '   AND    record_type_code = ' || gc_rec_type_inst
             || ' ) imld '
              ;
--
    -- ====================================================
    -- �v�g�d�q�d��
    -- ====================================================
    -------------------------------------------------------
    -- �\��m��敪���u�m��v
    -------------------------------------------------------
    lv_where := ' WHERE '
        || '     wsdit2.notif_status      = ''' || gc_notif_status_c || ''' '  -- �m��ʒm��
        || ' AND wsdit2.prev_notif_status = ''' || gc_notif_status_r || ''' '  -- �Ēʒm�v
        ;
--
    -------------------------------------------------------
    -- EOS��������i���ɁE�o�ɁE�^���Ǝ҂�EOS���悢���ꂩ���ݒ肳��Ă�����j
    -------------------------------------------------------
    lv_where := lv_where
            || ' AND ( wsdit2.eos_shipped_to_locat IS NOT NULL   '  -- EOS����i���ɑq�Ɂj
            || '    OR wsdit2.eos_shipped_locat    IS NOT NULL   '  -- EOS����i�o�ɑq�Ɂj
            || '    OR wsdit2.eos_freight_carrier  IS NOT NULL ) '  -- EOS����i�^���Ǝҁj
            ;
--
    -------------------------------------------------------
    -- �ړ����b�g�ڍׂƌ���
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND wsdit2.line_id = imld.mov_line_id (+) '
             ;
--
    -------------------------------------------------------
    -- �p�����[�^�D����
    -------------------------------------------------------
    lv_where := lv_where
             || ' AND ((wsdit2.report_dept = ''' || gr_param.dept_code_01 || ''')';
--
    IF (gr_param.dept_code_02 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_02 || ''')';
    END IF;
    IF (gr_param.dept_code_03 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_03 || ''')';
    END IF;
    IF (gr_param.dept_code_04 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_04 || ''')';
    END IF;
    IF (gr_param.dept_code_05 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_05 || ''')';
    END IF;
    IF (gr_param.dept_code_06 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_06 || ''')';
    END IF;
    IF (gr_param.dept_code_07 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_07 || ''')';
    END IF;
    IF (gr_param.dept_code_08 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_08 || ''')';
    END IF;
    IF (gr_param.dept_code_09 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_09 || ''')';
    END IF;
    IF (gr_param.dept_code_10 IS NOT NULL) THEN
      lv_where := lv_where
             || '  OR  (wsdit2.report_dept = ''' || gr_param.dept_code_10 || ''')';
    END IF;
--
    lv_where := lv_where || ')';
--
    -------------------------------------------------------
    -- �v��ID
    -------------------------------------------------------
    lv_where := lv_where || ' AND wsdit2.target_request_id = ' || TO_CHAR(gn_request_id) || ' ' ;
--
    -- ====================================================
    -- �f�q�n�t�o �a�x��
    -- ====================================================
    lv_group := ' GROUP BY '
            ||  ' wsdit2.request_no ';
--
    -- ====================================================
    -- �n�q�c�d�q �a�x��
    -- ====================================================
    lv_order  := ' ORDER BY '
              || '  wsdit2.request_no '
              ;
--
    -- ====================================================
    -- �r�p�k������
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_group || lv_order ;
--
    -- ====================================================
    -- ���C�� �r�d�k�d�b�s ����
    -- ====================================================
    lv_main_sql := ' SELECT g_req.request_no '
                || ' FROM ( ' || lv_sql  || ' ) g_req '
                || ' WHERE g_req.sum_quantity = 0 '
                ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    OPEN cu_ref FOR lv_main_sql ;
    FETCH cu_ref BULK COLLECT INTO gt_zero_can_data ;
    CLOSE cu_ref ;
--
    IF ( gt_zero_can_data.COUNT = 0 ) THEN
      RAISE ex_no_data ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- �Ώۃf�[�^�Ȃ�
    -- =============================================================================================
    WHEN ex_no_data THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                     ,iv_name           => lc_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
--
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cu_ref%ISOPEN THEN
        CLOSE cu_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_get_zero_can_data ;
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
--
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_head_data
   * Description      : �w�b�_�f�[�^�쐬
   ************************************************************************************************/
  PROCEDURE prc_cre_head_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_stock_delivery_info_tmp.data_class%TYPE
     ,iv_pallet_sum_quantity  IN  xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
     ,iv_eos_shipped_locat    IN  xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
     ,iv_eos_csv_output       IN  xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_cre_head_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_corporation_name     CONSTANT VARCHAR2(100) := 'ITOEN' ;
    lc_transfer_branch_no_h CONSTANT VARCHAR2(100) := '10' ;    -- �w�b�_
    lc_reserve              CONSTANT VARCHAR2(100) := '000000000000' ;
--
  BEGIN
    -- ==================================================
    -- �z��C���f�b�N�X�ҏW
    -- ==================================================
    gn_cre_idx := gn_cre_idx + 1 ;
--
    -- ==================================================
    -- ���ڕҏW����
    -- ==================================================
    gt_corporation_name(gn_cre_idx)       := lc_corporation_name ;                -- ��Ж�
    gt_data_class(gn_cre_idx)             := iv_data_class ;                      -- �f�[�^���
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_h ;            -- �`���p�}��
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ;           -- �z��No
    gt_request_no(gn_cre_idx)             := ir_main_data.request_no ;            -- �˗�No
    gt_reserve(gn_cre_idx)                := lc_reserve ;                         -- �\��
    gt_head_sales_branch(gn_cre_idx)      := ir_main_data.head_sales_branch ;     -- ���_�R�[�h
    gt_head_sales_branch_name(gn_cre_idx) := ir_main_data.head_sales_branch_name ;-- �Ǌ����_����
    gt_shipped_locat_code(gn_cre_idx)     := ir_main_data.shipped_locat_code ;    -- �o�ɑq�ɃR�[�h
    gt_shipped_locat_name(gn_cre_idx)     := ir_main_data.shipped_locat_name ;    -- �o�ɑq�ɖ���
    gt_ship_to_locat_code(gn_cre_idx)     := ir_main_data.ship_to_locat_code ;    -- ���ɑq�ɃR�[�h
    gt_ship_to_locat_name(gn_cre_idx)     := ir_main_data.ship_to_locat_name ;    -- ���ɑq�ɖ���
    gt_freight_carrier_code(gn_cre_idx)   := ir_main_data.freight_carrier_code ;  -- �^���Ǝ҃R�[�h
    gt_freight_carrier_name(gn_cre_idx)   := ir_main_data.freight_carrier_name ;  -- �^���ƎҖ�
    gt_deliver_to(gn_cre_idx)             := ir_main_data.deliver_to ;            -- �z����R�[�h
    gt_deliver_to_name(gn_cre_idx)        := ir_main_data.deliver_to_name ;       -- �z���於
    gt_schedule_ship_date(gn_cre_idx)     := ir_main_data.schedule_ship_date ;    -- ����
    gt_schedule_arrival_date(gn_cre_idx)  := ir_main_data.schedule_arrival_date ; -- ����
    gt_shipping_method_code(gn_cre_idx)   := ir_main_data.shipping_method_code ;  -- �z���敪
    gt_weight(gn_cre_idx)                 := ir_main_data.weight ;                -- �d��/�e��
    gt_mixed_no(gn_cre_idx)               := ir_main_data.mixed_no ;              -- ���ڌ��˗�No
    gt_collected_pallet_qty(gn_cre_idx)   := ir_main_data.collected_pallet_qty ;  -- ��گĉ������
    gt_arrival_time_from(gn_cre_idx)      := ir_main_data.arrival_time_from ;     -- ���׎���From
    gt_arrival_time_to(gn_cre_idx)        := ir_main_data.arrival_time_to ;       -- ���׎���To
    gt_cust_po_number(gn_cre_idx)         := ir_main_data.cust_po_number ;        -- �ڋq�����ԍ�
    gt_description(gn_cre_idx)            := ir_main_data.description ;           -- �E�v
--
    -- �X�e�[�^�X
    IF ( gr_param.fix_class = gc_fix_class_y ) THEN
      gt_status(gn_cre_idx) := gc_status_y ;
    ELSE
      gt_status(gn_cre_idx) := gc_status_k ;
    END IF ;
--
    gt_freight_charge_class(gn_cre_idx)   := ir_main_data.freight_charge_class ;-- �^���敪
    gt_pallet_sum_quantity(gn_cre_idx)    := iv_pallet_sum_quantity ;           -- ��گĎg�p����
    gt_reserve1(gn_cre_idx)               := NULL ;                             -- �\���P
    gt_reserve2(gn_cre_idx)               := NULL ;                             -- �\���Q
    gt_reserve3(gn_cre_idx)               := NULL ;                             -- �\���R
    gt_reserve4(gn_cre_idx)               := NULL ;                             -- �\���S
    gt_report_dept(gn_cre_idx)            := ir_main_data.report_dept ;         -- �񍐕���
    gt_item_code(gn_cre_idx)              := NULL ;                             -- �i�ڃR�[�h
    gt_item_name(gn_cre_idx)              := NULL ;                             -- �i�ږ�
    gt_item_uom_code(gn_cre_idx)          := NULL ;                             -- �i�ڒP��
    gt_item_quantity(gn_cre_idx)          := NULL ;                             -- �i�ڐ���
    gt_lot_no(gn_cre_idx)                 := NULL ;                             -- ���b�g�ԍ�
    gt_lot_date(gn_cre_idx)               := NULL ;                             -- ������
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                             -- �ܖ�����
    gt_lot_sign(gn_cre_idx)               := NULL ;                             -- �ŗL�L��
    gt_lot_quantity(gn_cre_idx)           := NULL ;                             -- ���b�g����
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;                -- �f�[�^�敪
    gt_update_date(gn_cre_idx)            := SYSDATE ;                          -- �X�V����
    gt_line_number(gn_cre_idx)            := NULL ;                             -- ���הԍ�
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;           -- �f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
/***
    gt_eos_shipped_locat(gn_cre_idx)      := ir_main_data.eos_shipped_locat ;   -- EOS����F�o�ɑq��
***/
    gt_eos_shipped_locat(gn_cre_idx)      := iv_eos_shipped_locat ;             -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
    gt_eos_freight_carrier(gn_cre_idx)    := ir_main_data.eos_freight_carrier ; -- EOS����F�^���Ǝ�
    gt_eos_csv_output(gn_cre_idx)         := iv_eos_csv_output ;                -- EOS����FCSV
--
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
    gt_notif_date(gn_cre_idx)             := ir_main_data.notif_date ;          -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    gt_target_request_id(gn_cre_idx)      := gn_request_id;                     -- �v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_cre_head_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_cre_dtl_data
   * Description      : ���׃f�[�^�쐬
   ************************************************************************************************/
  PROCEDURE prc_cre_dtl_data
    (
      ir_main_data            IN  rec_main_data
     ,iv_data_class           IN  xxwsh_stock_delivery_info_tmp.data_class%TYPE
     ,iv_item_uom_code        IN  xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE
     ,iv_item_quantity        IN  xxwsh_stock_delivery_info_tmp.item_quantity%TYPE
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
     ,iv_eos_shipped_locat    IN  xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
     ,iv_eos_csv_output       IN  xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_cre_dtl_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_corporation_name     CONSTANT VARCHAR2(100) := 'ITOEN' ;
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- ����
    lc_reserve              CONSTANT VARCHAR2(100) := '000000000000' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_doc_type             xxinv_mov_lot_details.document_type_code%TYPE ;
--
  BEGIN
    -- ==================================================
    -- �z��C���f�b�N�X�ҏW
    -- ==================================================
    gn_cre_idx := gn_cre_idx + 1 ;
--
    -- ==================================================
    -- ���ڕҏW����
    -- ==================================================
    gt_corporation_name(gn_cre_idx)       := lc_corporation_name ;              -- ��Ж�
    gt_data_class(gn_cre_idx)             := iv_data_class ;                    -- �f�[�^���
    gt_transfer_branch_no(gn_cre_idx)     := lc_transfer_branch_no_d ;          -- �`���p�}��
    gt_delivery_no(gn_cre_idx)            := ir_main_data.delivery_no ;         -- �z��No
    gt_request_no(gn_cre_idx)             := ir_main_data.request_no ;          -- �˗�No
    gt_reserve(gn_cre_idx)                := NULL ;                             -- �\��
    gt_head_sales_branch(gn_cre_idx)      := NULL ;                             -- ���_�R�[�h
    gt_head_sales_branch_name(gn_cre_idx) := NULL ;                             -- �Ǌ����_����
    gt_shipped_locat_code(gn_cre_idx)     := NULL ;                             -- �o�ɑq�ɃR�[�h
    gt_shipped_locat_name(gn_cre_idx)     := NULL ;                             -- �o�ɑq�ɖ���
    gt_ship_to_locat_code(gn_cre_idx)     := NULL ;                             -- ���ɑq�ɃR�[�h
    gt_ship_to_locat_name(gn_cre_idx)     := NULL ;                             -- ���ɑq�ɖ���
    gt_freight_carrier_code(gn_cre_idx)   := NULL ;                             -- �^���Ǝ҃R�[�h
    gt_freight_carrier_name(gn_cre_idx)   := NULL ;                             -- �^���ƎҖ�
    gt_deliver_to(gn_cre_idx)             := NULL ;                             -- �z����R�[�h
    gt_deliver_to_name(gn_cre_idx)        := NULL ;                             -- �z���於
    gt_schedule_ship_date(gn_cre_idx)     := NULL ;                             -- ����
    gt_schedule_arrival_date(gn_cre_idx)  := NULL ;                             -- ����
    gt_shipping_method_code(gn_cre_idx)   := NULL ;                             -- �z���敪
    gt_weight(gn_cre_idx)                 := NULL ;                             -- �d��/�e��
    gt_mixed_no(gn_cre_idx)               := NULL ;                             -- ���ڌ��˗�No
    gt_collected_pallet_qty(gn_cre_idx)   := NULL ;                             -- ��گĉ������
    gt_arrival_time_from(gn_cre_idx)      := NULL ;                             -- ���׎���From
    gt_arrival_time_to(gn_cre_idx)        := NULL ;                             -- ���׎���To
    gt_cust_po_number(gn_cre_idx)         := NULL ;                             -- �ڋq�����ԍ�
    gt_description(gn_cre_idx)            := NULL ;                             -- �E�v
    gt_status(gn_cre_idx)                 := NULL ;                             -- �X�e�[�^�X
    gt_freight_charge_class(gn_cre_idx)   := NULL ;                             -- �^���敪
    gt_pallet_sum_quantity(gn_cre_idx)    := NULL ;                             -- ��گĎg�p����
    gt_reserve1(gn_cre_idx)               := NULL ;                             -- �\���P
    gt_reserve2(gn_cre_idx)               := NULL ;                             -- �\���Q
    gt_reserve3(gn_cre_idx)               := NULL ;                             -- �\���R
    gt_reserve4(gn_cre_idx)               := NULL ;                             -- �\���S
    gt_report_dept(gn_cre_idx)            := NULL ;                             -- �񍐕���
    gt_item_code(gn_cre_idx)              := ir_main_data.item_code ;           -- �i�ڃR�[�h
    gt_item_name(gn_cre_idx)              := ir_main_data.item_name ;           -- �i�ږ�
    gt_item_uom_code(gn_cre_idx)          := iv_item_uom_code ;                 -- �i�ڒP��
    gt_item_quantity(gn_cre_idx)          := iv_item_quantity ;                 -- �i�ڐ���
    gt_lot_no(gn_cre_idx)                 := NULL ;                             -- ���b�g�ԍ�
    gt_lot_date(gn_cre_idx)               := NULL ;                             -- ������
    gt_best_bfr_date(gn_cre_idx)          := NULL ;                             -- �ܖ�����
    gt_lot_sign(gn_cre_idx)               := NULL ;                             -- �ŗL�L��
    gt_lot_quantity(gn_cre_idx)           := NULL ;                             -- ���b�g����
    gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_ins ;                -- �f�[�^�敪
    gt_update_date(gn_cre_idx)            := SYSDATE ;                          -- �X�V����
    gt_line_number(gn_cre_idx)            := ir_main_data.line_number ;         -- ���הԍ�
    gt_data_type(gn_cre_idx)              := ir_main_data.data_type ;           -- �f�[�^�^�C�v
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
/***
    gt_eos_shipped_locat(gn_cre_idx)      := ir_main_data.eos_shipped_locat ;   -- EOS����F�o�ɑq��
***/
    gt_eos_shipped_locat(gn_cre_idx)      := iv_eos_shipped_locat ;             -- EOS����
    
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
    gt_eos_freight_carrier(gn_cre_idx)    := ir_main_data.eos_freight_carrier ; -- EOS����F�^���Ǝ�
    gt_eos_csv_output(gn_cre_idx)         := iv_eos_csv_output ;                -- EOS����FCSV
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
    gt_notif_date(gn_cre_idx)             := ir_main_data.notif_date ;          -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    gt_target_request_id(gn_cre_idx)      := gn_request_id;                     -- �v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
    -------------------------------------------------------
    -- ���b�g�Ǘ��i�̏ꍇ
    -------------------------------------------------------
    IF ( ir_main_data.lot_class = gc_lot_ctl_y ) THEN
      -- �o�׃f�[�^�̏ꍇ
      IF ( iv_data_class IN( gc_data_class_syu_s
                            ,gc_data_class_syu_h ) ) THEN
--
        lv_doc_type := gc_doc_type_ship ;
--
      -- �x���f�[�^�̏ꍇ
      ELSIF ( iv_data_class IN( gc_data_class_shi_s
                               ,gc_data_class_shi_h ) ) THEN
--
        lv_doc_type := gc_doc_type_prov ;
--
      -- �ړ��f�[�^�̏ꍇ
      ELSIF ( iv_data_class IN( gc_data_class_mov_s
                            ,gc_data_class_mov_h 
                            ,gc_data_class_mov_n ) ) THEN
--
        lv_doc_type := gc_doc_type_move ;
--
      END IF ;
--
      -- ���b�g��񒊏o
      BEGIN
        SELECT ilm.lot_no
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute3 )
              ,ilm.attribute2
              ,xmld.actual_quantity
        INTO   gt_lot_no(gn_cre_idx)           -- ���b�g�ԍ�
              ,gt_lot_date(gn_cre_idx)         -- ������
              ,gt_best_bfr_date(gn_cre_idx)    -- �ܖ�����
              ,gt_lot_sign(gn_cre_idx)         -- �ŗL�L��
              ,gt_lot_quantity(gn_cre_idx)     -- ���b�g����
        FROM xxinv_mov_lot_details    xmld    -- �ړ����b�g�ڍ׃A�h�I��
            ,ic_lots_mst              ilm     -- �n�o�l���b�g�}�X�^
        WHERE ilm.inactive_ind  = gc_inactive_ind_y   -- 0�F�L��
        AND   ilm.delete_mark   = gc_delete_mark_y    -- 0�F���폜
        AND   xmld.lot_id       = ilm.lot_id
        AND   xmld.document_type_code = lv_doc_type
        AND   xmld.record_type_code   = gc_rec_type_inst    -- 10�F�w��
        AND   xmld.item_id            = ir_main_data.item_id
        AND   xmld.mov_line_id        = ir_main_data.line_id
        AND   xmld.mov_lot_dtl_id     = ir_main_data.mov_lot_dtl_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_lot_no(gn_cre_idx)        := NULL ;     -- ���b�g�ԍ�
          gt_lot_date(gn_cre_idx)      := NULL ;     -- ������
          gt_best_bfr_date(gn_cre_idx) := NULL ;     -- �ܖ�����
          gt_lot_sign(gn_cre_idx)      := NULL ;     -- �ŗL�L��
          gt_lot_quantity(gn_cre_idx)  := NULL ;     -- ���b�g����
      END ;
--
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
      -------------------------------------------------------
      -- ���b�g���ʊ��Z
      -------------------------------------------------------
      -- �o�ׂ̏ꍇ
      IF ( ir_main_data.data_type = gc_data_type_syu_ins ) THEN
--
        -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ�̊��Z
        IF (ir_main_data.conv_unit IS NOT NULL) THEN
          -- ���b�g���� �� �P�[�X���萔
          gt_lot_quantity(gn_cre_idx) := gt_lot_quantity(gn_cre_idx)
                                            / ir_main_data.case_quantity ;
          --gt_lot_quantity(gn_cre_idx) := TRUNC( gt_lot_quantity(gn_cre_idx), 3 ) ; --2008/08/12 Del �ۑ�#32
--
        END IF;
--
      -- �ړ��̏ꍇ�i�h�����N���i�̂݁j
      ELSIF (   ( ir_main_data.data_type  = gc_data_type_mov_ins )
            AND ( ir_main_data.prod_class = gc_prod_class_d      ) 
            AND ( ir_main_data.item_class = gc_item_class_i      ) ) THEN
        -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
        IF (ir_main_data.conv_unit IS NOT NULL) THEN
          -- ���b�g���� �� �P�[�X���萔
          gt_lot_quantity(gn_cre_idx) := gt_lot_quantity(gn_cre_idx)
                                            / ir_main_data.case_quantity ;
          --gt_lot_quantity(gn_cre_idx) := TRUNC( gt_lot_quantity(gn_cre_idx), 3 ) ; --2008/08/12 Del �ۑ�#32
        END IF ;
      END IF;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
--
    END IF ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_cre_dtl_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_ins_data
   * Description      : �ʒm�Ϗ��쐬����(E-05)
   ************************************************************************************************/
  PROCEDURE prc_create_ins_data
    (
      in_idx          IN  NUMBER            -- �Ώۃf�[�^�z��C���f�b�N�X
     ,iv_break_flg    IN  VARCHAR2          -- �˗��m���u���C�N�t���O
     ,ov_errbuf       OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode      OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg       OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_ins_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code_eos         CONSTANT VARCHAR2(50) := 'APP-XXWSH-11908' ;
    lc_msg_code_case        CONSTANT VARCHAR2(50) := 'APP-XXWSH-11904' ;
    lc_tok_name_eos         CONSTANT VARCHAR2(50) := 'REQ_NO' ;
    lc_tok_name_case        CONSTANT VARCHAR2(50) := 'ITEM_ID' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
    lv_eos_shipped_to_locat xxwsh_stock_delivery_info_tmp2.eos_shipped_to_locat%TYPE ;
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
    lv_eos_shipped_locat    xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE ;
    lv_eos_freight_carrier  xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE ;
    lv_eos_csv_output       xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE ;
    lv_pallet_sum_quantity  xxwsh_stock_delivery_info_tmp.pallet_sum_quantity%TYPE ;
    lv_item_uom_code        xxwsh_stock_delivery_info_tmp.item_uom_code%TYPE ;
    lv_item_quantity        xxwsh_stock_delivery_info_tmp.item_quantity%TYPE ;
--
    lv_eos_wrk              xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE;
--
    lv_tok_val              VARCHAR2(50) ;
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_eos_error            EXCEPTION ;   -- �d�n�r����G���[
    ex_case_quant_error     EXCEPTION ;   -- �P�[�X���萔�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- =============================================================================================
    -- ��������
    -- =============================================================================================
    -------------------------------------------------------
    -- �d�n�r����̑ޔ�
    -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
    lv_eos_shipped_to_locat := gt_main_data(in_idx).eos_shipped_to_locat ;
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
    lv_eos_shipped_locat    := gt_main_data(in_idx).eos_shipped_locat ;
    lv_eos_freight_carrier  := gt_main_data(in_idx).eos_freight_carrier ;
--
    -- =============================================================================================
    -- �G���[�n���h�����O
    -- =============================================================================================
    -------------------------------------------------------
    -- �d�n�r����`�F�b�N
    -------------------------------------------------------
    lv_tok_val := gt_main_data(in_idx).request_no ;
-- M.Hokkanji Ver1.5 START
-- �^���Ǝ҂�NULL�̏ꍇ���G���[�ɂ��Ȃ��悤�ɏC��
--    IF ( lv_eos_freight_carrier IS NULL ) THEN
--      RAISE ex_eos_error ;
--    END IF ;
-- M.Hokkanji Ver1.5 END
--
    -------------------------------------------------------
    -- �P�[�X���萔�`�F�b�N
    -------------------------------------------------------
    lv_tok_val := gt_main_data(in_idx).item_code ;
    -- �o�ׂ̏ꍇ
    IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
      -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
        -- �P�[�X���萔�̒l���Ȃ��ꍇ
        IF ( NVL( gt_main_data(in_idx).case_quantity, 0 ) = 0 ) THEN
          RAISE ex_case_quant_error ;
        END IF ;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
      END IF ;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
--
    -- �ړ��̏ꍇ�i�h�����N���i�̂݁j
    ELSIF (   ( gt_main_data(in_idx).data_type  = gc_data_type_mov_ins )
          AND ( gt_main_data(in_idx).prod_class = gc_prod_class_d      ) 
          AND ( gt_main_data(in_idx).item_class = gc_item_class_i      ) ) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
      -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
        -- �P�[�X���萔�̒l���Ȃ��ꍇ
        IF ( NVL( gt_main_data(in_idx).case_quantity, 0 ) = 0 ) THEN
          RAISE ex_case_quant_error ;
        END IF ;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
      END IF ;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
    END IF ;
--
    -- =============================================================================================
    -- �o�׈˗��f�[�^�쐬
    -- =============================================================================================
    lv_eos_csv_output := lv_eos_shipped_locat ;   -- �d�n�r����i�b�r�u�j
    -------------------------------------------------------
    -- �f�[�^�^�C�v�F�o��
    -------------------------------------------------------
    IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
      -------------------------------------------------------
      -- �ύ��ڕҏW
      -------------------------------------------------------
      lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;  -- �p���b�g�g�p����
--
      -- �i�ڒP��
      lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                              ,gt_main_data(in_idx).item_uom_code ) ;
      -- �i�ڐ���
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
      -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
        lv_item_quantity := gt_main_data(in_idx).item_quantity
                          / gt_main_data(in_idx).case_quantity ;
        --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;       --2008/08/12 Del �ۑ�#32
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
      -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
      ELSE
        lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- �i�ڐ���
      END IF;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
      -- �o�ɑq�ɂ�EOS���悪�ݒ肳��Ă���ꍇ
      IF (lv_eos_shipped_locat IS NOT NULL) THEN
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
--
        -------------------------------------------------------
        -- �w�b�_�f�[�^�̍쐬
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
              ,iv_data_class           => gc_data_class_syu_s      -- �f�[�^���
              ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
              ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
              ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
              ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
              ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
              ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
        -------------------------------------------------------
        -- ���׃f�[�^�̍쐬
        -------------------------------------------------------
        -- ���ׂ̍폜�t���O���uY�v�̏ꍇ�A���׃f�[�^���쐬���Ȃ��B
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_syu_s      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
      END IF ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
--
    -------------------------------------------------------
    -- �f�[�^�^�C�v�F�x��
    -------------------------------------------------------
    ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_shi_ins ) THEN
      -------------------------------------------------------
      -- �ύ��ڕҏW
      -------------------------------------------------------
      lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;  -- �p���b�g�g�p����
      lv_item_uom_code       := gt_main_data(in_idx).item_uom_code  ;           -- �i�ڒP��
      lv_item_quantity       := gt_main_data(in_idx).item_quantity ;            -- �i�ڐ���
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
      -- �o�ɑq�ɂ�EOS���悪�ݒ肳��Ă���ꍇ
      IF (lv_eos_shipped_locat IS NOT NULL) THEN
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
        -------------------------------------------------------
        -- �w�b�_�f�[�^�̍쐬
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_shi_s      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
        -------------------------------------------------------
        -- ���׃f�[�^�̍쐬
        -------------------------------------------------------
        -- ���ׂ̍폜�t���O���uY�v�̏ꍇ�A���׃f�[�^���쐬���Ȃ��B
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_shi_s      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
      END IF ;
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
--
    -------------------------------------------------------
    -- �f�[�^�^�C�v�F�ړ�
    -------------------------------------------------------
    ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_mov_ins ) THEN
      -------------------------------------------------------
      -- �ύ��ڕҏW
      -------------------------------------------------------
      -- �h�����N���i�̏ꍇ
      IF (   ( gt_main_data(in_idx).prod_class = gc_prod_class_d )
         AND ( gt_main_data(in_idx).item_class = gc_item_class_i ) ) THEN
--
        -- �i�ڒP��
        lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                                ,gt_main_data(in_idx).item_uom_code ) ;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
        -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
        IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
          -- �i�ڐ���
          lv_item_quantity := gt_main_data(in_idx).item_quantity
                            / gt_main_data(in_idx).case_quantity ;
          --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;       --2008/08/12 Del �ۑ�#32
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
        -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
        ELSE
          lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- �i�ڐ���
        END IF;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
--
      ELSE
--
        lv_item_uom_code := gt_main_data(in_idx).item_uom_code  ;   -- �i�ڒP��
        lv_item_quantity := gt_main_data(in_idx).item_quantity  ;   -- �i�ڐ���
--
      END IF ;
--
      -------------------------------------------------------
      -- �w�b�_�f�[�^�̍쐬
      -------------------------------------------------------
      IF ( iv_break_flg = gc_yes_no_y ) THEN
        -------------------------------------------------------
        -- �ړ��o�ɂ̍쐬
        -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        -- EOS����i�o�ɑq�Ɂj���ݒ肳��Ă���ꍇ
        IF (gt_main_data(in_idx).eos_shipped_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_locat ;   -- �d�n�r����i�b�r�u�j
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_s      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
--
        -------------------------------------------------------
        -- �ړ����ɂ̍쐬
        -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        -- EOS����i���ɑq�Ɂj���ݒ肳��Ă���ꍇ
        IF (gt_main_data(in_idx).eos_shipped_to_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_to_locat ;   -- �d�n�r����i�b�r�u�j
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_in ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_n      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_to_locat  -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
      END IF ;
--
      -- ���ׂ̍폜�t���O���uY�v�̏ꍇ�A���׃f�[�^���쐬���Ȃ��B
      IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          -------------------------------------------------------
          -- ���׃f�[�^�̍쐬�i�ړ��o�Ɂj
          -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        -- EOS����i�o�ɑq�Ɂj���ݒ肳��Ă���ꍇ
        IF (gt_main_data(in_idx).eos_shipped_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_locat ;   -- �d�n�r����i�b�r�u�j
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_s      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat      => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
        -------------------------------------------------------
        -- ���׃f�[�^�̍쐬�i�ړ����Ɂj
        -------------------------------------------------------
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        -- EOS����i���ɑq�Ɂj���ݒ肳��Ă���ꍇ
        IF (gt_main_data(in_idx).eos_shipped_to_locat IS NOT NULL) THEN
          lv_eos_csv_output := lv_eos_shipped_to_locat ;   -- �d�n�r����i�b�r�u�j
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_n      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_to_locat  -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
        END IF;
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
      END IF ;
--
    END IF ;
--
    -- =============================================================================================
    -- �z���˗��f�[�^�쐬
    -- =============================================================================================
    lv_eos_csv_output := lv_eos_freight_carrier ;   -- �d�n�r����i�b�r�u�j
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
/***
       AND ( lv_eos_freight_carrier <> lv_eos_shipped_locat ) ) THEN
***/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/*****
    IF (   ( lv_eos_freight_carrier IS NOT NULL             )
       AND ( lv_eos_freight_carrier <> NVL(lv_eos_shipped_locat   ,lv_eos_shipped_to_locat))
       AND ( lv_eos_freight_carrier <> NVL(lv_eos_shipped_to_locat, lv_eos_shipped_locat))) THEN
*****/
    -- �^���Ǝ҂�EOS���悪�ݒ肹��Ă��āA�o�ɂ�EOS�ƈقȂ�ꍇ
    --   �z���˗��f�[�^���o�͂���
    --   ���ɑq�ɂƓ���̏ꍇ�́A�z���˗����o�͂���
    IF  ( lv_eos_freight_carrier  IS NOT NULL )
-- ##### 20081006 Ver.1.21 ����#306�Ή� START #####
/*****
    AND ((lv_eos_shipped_locat    IS NULL) OR ( lv_eos_freight_carrier <> lv_eos_shipped_locat))
    AND ((lv_eos_shipped_to_locat IS NULL) OR ( lv_eos_freight_carrier <> lv_eos_shipped_to_locat)) THEN
*****/
    AND ((lv_eos_shipped_locat IS NULL) OR ( lv_eos_freight_carrier <> lv_eos_shipped_locat )) THEN
-- ##### 20081006 Ver.1.21 ����#306�Ή� END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
      -------------------------------------------------------
      -- �f�[�^�^�C�v�F�o��
      -------------------------------------------------------
      IF ( gt_main_data(in_idx).data_type = gc_data_type_syu_ins ) THEN
        -------------------------------------------------------
        -- �ύ��ڕҏW
        -------------------------------------------------------
        lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
--
        -- �i�ڒP��
        lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                                ,gt_main_data(in_idx).item_uom_code ) ;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
      -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
      IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
        lv_item_quantity := gt_main_data(in_idx).item_quantity
                          / gt_main_data(in_idx).case_quantity ;
        --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;      --2008/08/12 Del �ۑ�#32
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
      -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
      ELSE
        lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- �i�ڐ���
      END IF;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
--
        -------------------------------------------------------
        -- �w�b�_�f�[�^�̍쐬
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_syu_h      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat   -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
        -------------------------------------------------------
        -- ���׃f�[�^�̍쐬
        -------------------------------------------------------
        -- ���ׂ̍폜�t���O���uY�v�̏ꍇ�A���׃f�[�^���쐬���Ȃ��B
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_syu_h      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
--
      -------------------------------------------------------
      -- �f�[�^�^�C�v�F�x��
      -------------------------------------------------------
      ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_shi_ins ) THEN
        -------------------------------------------------------
        -- �ύ��ڕҏW
        -------------------------------------------------------
        lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
        lv_item_uom_code       := gt_main_data(in_idx).item_uom_code  ;           -- �i�ڒP��
        lv_item_quantity       := gt_main_data(in_idx).item_quantity ;            -- �i�ڐ���
--
        -------------------------------------------------------
        -- �w�b�_�f�[�^�̍쐬
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_shi_h      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
        -------------------------------------------------------
        -- ���׃f�[�^�̍쐬
        -------------------------------------------------------
        -- ���ׂ̍폜�t���O���uY�v�̏ꍇ�A���׃f�[�^���쐬���Ȃ��B
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_shi_h      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
        END IF ;
--
      -------------------------------------------------------
      -- �f�[�^�^�C�v�F�ړ�
      -------------------------------------------------------
      ELSIF ( gt_main_data(in_idx).data_type = gc_data_type_mov_ins ) THEN
        -------------------------------------------------------
        -- �ύ��ڕҏW
        -------------------------------------------------------
      -- �h�����N���i�̏ꍇ
      IF (   ( gt_main_data(in_idx).prod_class = gc_prod_class_d )
         AND ( gt_main_data(in_idx).item_class = gc_item_class_i ) ) THEN
--
        -- �i�ڒP��
        lv_item_uom_code := NVL( gt_main_data(in_idx).conv_unit
                                ,gt_main_data(in_idx).item_uom_code ) ;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
        -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
        IF (gt_main_data(in_idx).conv_unit IS NOT NULL) THEN
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
          -- �i�ڐ���
          lv_item_quantity := gt_main_data(in_idx).item_quantity
                            / gt_main_data(in_idx).case_quantity ;
          --lv_item_quantity := TRUNC( lv_item_quantity, 3 ) ;      --2008/08/12 Del �ۑ�#32
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� START #####
--
        -- ���o�Ɋ��Z�P�ʁ�NULL�̏ꍇ
        ELSE
          lv_item_quantity       := gt_main_data(in_idx).item_quantity ;  -- �i�ڐ���
        END IF;
-- ##### 20080627 Ver.1.11 ���b�g���ʊ��Z�Ή� END   #####
--
      ELSE
--
        lv_item_uom_code := gt_main_data(in_idx).item_uom_code  ;   -- �i�ڒP��
        lv_item_quantity := gt_main_data(in_idx).item_quantity  ;   -- �i�ڐ���
--
      END IF ;
--
        -------------------------------------------------------
        -- �w�b�_�f�[�^�̍쐬
        -------------------------------------------------------
        IF ( iv_break_flg = gc_yes_no_y ) THEN
          -------------------------------------------------------
          -- �ړ��o�ɂ̍쐬
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_out ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_h      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
/***
          -------------------------------------------------------
          -- �ړ����ɂ̍쐬
          -------------------------------------------------------
          lv_pallet_sum_quantity := gt_main_data(in_idx).pallet_sum_quantity_in ;
          prc_cre_head_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_n      -- �f�[�^���
             ,iv_pallet_sum_quantity  => lv_pallet_sum_quantity   -- �p���b�g�g�p����
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
***/
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
        END IF ;
--
        -- ���ׂ̍폜�t���O���uY�v�̏ꍇ�A���׃f�[�^���쐬���Ȃ��B
        IF ( gt_main_data(in_idx).line_delete_flag = gc_delete_flag_n ) THEN
          -------------------------------------------------------
          -- ���׃f�[�^�̍쐬�i�ړ��o�Ɂj
          -------------------------------------------------------
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_h      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
             ,iv_eos_shipped_locat    => lv_eos_shipped_locat     -- EOS����
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
-- ##### 20080623 Ver.1.9 EOS����Ή� START #####
/***
          -------------------------------------------------------
          -- ���׃f�[�^�̍쐬�i�ړ����Ɂj
          -------------------------------------------------------
          prc_cre_dtl_data
            (
              ir_main_data            => gt_main_data(in_idx)     -- �Ώۃf�[�^
             ,iv_data_class           => gc_data_class_mov_n      -- �f�[�^���
             ,iv_item_uom_code        => lv_item_uom_code         -- �i�ڒP��
             ,iv_item_quantity        => lv_item_quantity         -- �i�ڐ���
             ,iv_eos_csv_output       => lv_eos_csv_output        -- �d�n�r����i�b�r�u�j
             ,ov_errbuf               => lv_errbuf                -- �G���[�E���b�Z�[�W
             ,ov_retcode              => lv_retcode               -- ���^�[���E�R�[�h
             ,ov_errmsg               => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
            ) ;
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
***/
-- ##### 20080623 Ver.1.9 EOS����Ή� END   #####
        END IF ;
--
      END IF ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- �d�n�r����G���[
    -- =============================================================================================
    WHEN ex_eos_error THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code_eos
                       ,iv_token_name1    => lc_tok_name_eos
                       ,iv_token_value1   => lv_tok_val
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
    -- =============================================================================================
    -- �P�[�X���萔�G���[
    -- =============================================================================================
    WHEN ex_case_quant_error THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code_case
                       ,iv_token_name1    => lc_tok_name_case
                       ,iv_token_value1   => lv_tok_val
                      ) ;
      ov_errmsg    := lv_errmsg ;
      ov_errbuf    := lv_errmsg ;
      ov_retcode   := gv_status_error ;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_ins_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_can_data
   * Description      : �ύX�O������f�[�^�쐬����(E-06)
   ************************************************************************************************/
  PROCEDURE prc_create_can_data
    (
      iv_request_no           IN  xxwsh_stock_delivery_info_tmp.request_no%TYPE
     ,iv_eos_shipped_locat    IN  xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
     ,iv_eos_freight_carrier  IN  xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE
     ,ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_can_data' ; -- �v���O������
-- ##### 20080612 Ver.1.8 440�s��Ή�#68 START #####
    lc_transfer_branch_no_h     CONSTANT VARCHAR2(100) := '10' ;    -- �w�b�_
-- ##### 20080612 Ver.1.8 440�s��Ή�#68 END   #####
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    CURSOR cu_can_data
      (
        p_request_no            xxwsh_stock_delivery_info_tmp.request_no%TYPE
       ,p_eos_shipped_locat     xxwsh_stock_delivery_info_tmp.eos_shipped_locat%TYPE
       ,p_eos_freight_carrier   xxwsh_stock_delivery_info_tmp.eos_freight_carrier%TYPE
      )
    IS
      SELECT xndi.corporation_name            -- ��Ж�
            ,xndi.data_class                  -- �f�[�^���
            ,xndi.transfer_branch_no          -- �`���p�}��
            ,xndi.delivery_no                 -- �z��No
            ,xndi.request_no                  -- �˗�No
            ,xndi.reserve                     -- �\��
            ,xndi.head_sales_branch           -- ���_�R�[�h
            ,xndi.head_sales_branch_name      -- �Ǌ����_����
            ,xndi.shipped_locat_code          -- �o�ɑq�ɃR�[�h
            ,xndi.shipped_locat_name          -- �o�ɑq�ɖ���
            ,xndi.ship_to_locat_code          -- ���ɑq�ɃR�[�h
            ,xndi.ship_to_locat_name          -- ���ɑq�ɖ���
            ,xndi.freight_carrier_code        -- �^���Ǝ҃R�[�h
            ,xndi.freight_carrier_name        -- �^���ƎҖ�
            ,xndi.deliver_to                  -- �z����R�[�h
            ,xndi.deliver_to_name             -- �z���於
            ,xndi.schedule_ship_date          -- ����
            ,xndi.schedule_arrival_date       -- ����
            ,xndi.shipping_method_code        -- �z���敪
            ,xndi.weight                      -- �d��/�e��
            ,xndi.mixed_no                    -- ���ڌ��˗���
            ,xndi.collected_pallet_qty        -- �p���b�g�������
            ,xndi.arrival_time_from           -- ���׎��Ԏw��(FROM)
            ,xndi.arrival_time_to             -- ���׎��Ԏw��(TO)
            ,xndi.cust_po_number              -- �ڋq�����ԍ�
            ,xndi.description                 -- �E�v
            ,xndi.status                      -- �X�e�[�^�X
            ,xndi.freight_charge_class        -- �^���敪
            ,xndi.pallet_sum_quantity         -- �p���b�g�g�p����
            ,xndi.reserve1                    -- �\���P
            ,xndi.reserve2                    -- �\���Q
            ,xndi.reserve3                    -- �\���R
            ,xndi.reserve4                    -- �\���S
            ,xndi.report_dept                 -- �񍐕���
            ,xndi.item_code                   -- �i�ڃR�[�h
            ,xndi.item_name                   -- �i�ږ�
            ,xndi.item_uom_code               -- �i�ڒP��
            ,xndi.item_quantity               -- �i�ڐ���
            ,xndi.lot_no                      -- ���b�g�ԍ�
            ,xndi.lot_date                    -- ������
            ,xndi.best_bfr_date               -- �ܖ�����
            ,xndi.lot_sign                    -- �ŗL�L��
            ,xndi.lot_quantity                -- ���b�g����
            ,xndi.new_modify_del_class        -- �f�[�^�敪
            ,xndi.update_date                 -- �X�V����
            ,xndi.line_number                 -- ���הԍ�
            ,xndi.data_type                   -- �f�[�^�^�C�v
            ,xndi.eos_shipped_locat           -- EOS����i�o�ɑq�Ɂj
            ,xndi.eos_freight_carrier         -- EOS����i�^���Ǝҁj
            ,xndi.eos_csv_output              -- EOS����iCSV�o�́j
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xndi.notif_date                  -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
      FROM xxwsh_notif_delivery_info  xndi
      WHERE xndi.request_no = p_request_no
      ORDER BY xndi.request_no                -- �˗�No
              ,xndi.transfer_branch_no        -- �`���p�}��
              ,xndi.line_number               -- ���הԍ�
    ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ����f�[�^�쐬
    -- ====================================================
    <<can_data_loop>>
    FOR re_can_data IN cu_can_data
      ( p_request_no            => iv_request_no
       ,p_eos_shipped_locat     => iv_eos_shipped_locat
       ,p_eos_freight_carrier   => iv_eos_freight_carrier ) LOOP
--
      gn_cre_idx := gn_cre_idx + 1 ;
--
      gt_corporation_name(gn_cre_idx)       := re_can_data.corporation_name ;
      gt_data_class(gn_cre_idx)             := re_can_data.data_class ;
      gt_transfer_branch_no(gn_cre_idx)     := re_can_data.transfer_branch_no ;
      gt_delivery_no(gn_cre_idx)            := re_can_data.delivery_no ;
      gt_request_no(gn_cre_idx)             := re_can_data.request_no ;
      gt_reserve(gn_cre_idx)                := re_can_data.reserve ;
      gt_head_sales_branch(gn_cre_idx)      := re_can_data.head_sales_branch ;
      gt_head_sales_branch_name(gn_cre_idx) := re_can_data.head_sales_branch_name ;
      gt_shipped_locat_code(gn_cre_idx)     := re_can_data.shipped_locat_code ;
      gt_shipped_locat_name(gn_cre_idx)     := re_can_data.shipped_locat_name ;
      gt_ship_to_locat_code(gn_cre_idx)     := re_can_data.ship_to_locat_code ;
      gt_ship_to_locat_name(gn_cre_idx)     := re_can_data.ship_to_locat_name ;
      gt_freight_carrier_code(gn_cre_idx)   := re_can_data.freight_carrier_code ;
      gt_freight_carrier_name(gn_cre_idx)   := re_can_data.freight_carrier_name ;
      gt_deliver_to(gn_cre_idx)             := re_can_data.deliver_to ;
      gt_deliver_to_name(gn_cre_idx)        := re_can_data.deliver_to_name ;
      gt_schedule_ship_date(gn_cre_idx)     := re_can_data.schedule_ship_date ;
      gt_schedule_arrival_date(gn_cre_idx)  := re_can_data.schedule_arrival_date ;
      gt_shipping_method_code(gn_cre_idx)   := re_can_data.shipping_method_code ;
      gt_weight(gn_cre_idx)                 := re_can_data.weight ;
      gt_mixed_no(gn_cre_idx)               := re_can_data.mixed_no ;
      gt_collected_pallet_qty(gn_cre_idx)   := re_can_data.collected_pallet_qty ;
      gt_arrival_time_from(gn_cre_idx)      := re_can_data.arrival_time_from ;
      gt_arrival_time_to(gn_cre_idx)        := re_can_data.arrival_time_to ;
      gt_cust_po_number(gn_cre_idx)         := re_can_data.cust_po_number ;
      gt_description(gn_cre_idx)            := re_can_data.description ;
      gt_status(gn_cre_idx)                 := re_can_data.status ;
      gt_freight_charge_class(gn_cre_idx)   := re_can_data.freight_charge_class ;
      gt_pallet_sum_quantity(gn_cre_idx)    := re_can_data.pallet_sum_quantity ;
      gt_reserve1(gn_cre_idx)               := re_can_data.reserve1 ;
      gt_reserve2(gn_cre_idx)               := re_can_data.reserve2 ;
      gt_reserve3(gn_cre_idx)               := re_can_data.reserve3 ;
      gt_reserve4(gn_cre_idx)               := re_can_data.reserve4 ;
      gt_report_dept(gn_cre_idx)            := re_can_data.report_dept ;
      gt_item_code(gn_cre_idx)              := re_can_data.item_code ;
      gt_item_name(gn_cre_idx)              := re_can_data.item_name ;
      gt_item_uom_code(gn_cre_idx)          := re_can_data.item_uom_code ;
--
-- ##### 20080612 Ver.1.8 440�s��Ή�#68 START #####
      -- �`���p�}�Ԃ��u�w�b�_�v�̏ꍇ
      IF (re_can_data.transfer_branch_no =lc_transfer_branch_no_h) THEN
        gt_item_quantity(gn_cre_idx)          := NULL ;
      ELSE
        gt_item_quantity(gn_cre_idx)          := 0 ;
      END IF;
-- ##### 20080612 Ver.1.8 440�s��Ή�#68 END   #####
--
      gt_lot_no(gn_cre_idx)                 := re_can_data.lot_no ;
      gt_lot_date(gn_cre_idx)               := re_can_data.lot_date ;
      gt_best_bfr_date(gn_cre_idx)          := re_can_data.best_bfr_date ;
      gt_lot_sign(gn_cre_idx)               := re_can_data.lot_sign ;
--
-- ##### 20080612 Ver.1.8 440�s��Ή�#68 START #####
      -- �`���p�}�Ԃ��u�w�b�_�v�̏ꍇ
      IF (re_can_data.transfer_branch_no =lc_transfer_branch_no_h) THEN
        gt_lot_quantity(gn_cre_idx)           := NULL ;
      ELSE
        gt_lot_quantity(gn_cre_idx)           := 0 ;
      END IF;
-- ##### 20080612 Ver.1.8 440�s��Ή�#68 END   #####
--
      gt_new_modify_del_class(gn_cre_idx)   := gc_data_class_del ;
      gt_update_date(gn_cre_idx)            := SYSDATE ;
      gt_line_number(gn_cre_idx)            := re_can_data.line_number ;
      gt_data_type(gn_cre_idx)              := re_can_data.data_type ;
      gt_eos_shipped_locat(gn_cre_idx)      := re_can_data.eos_shipped_locat ;
      gt_eos_freight_carrier(gn_cre_idx)    := re_can_data.eos_freight_carrier ;
      gt_eos_csv_output(gn_cre_idx)         := re_can_data.eos_csv_output ;
--
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
      gt_notif_date(gn_cre_idx)             := re_can_data.notif_date ;
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    gt_target_request_id(gn_cre_idx)      := gn_request_id;                     -- �v��ID
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
--
    END LOOP can_data_loop ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_can_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_data
   * Description      : �ꊇ�o�^����(E-07)
   ************************************************************************************************/
  PROCEDURE prc_ins_temp_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_temp_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    ln_cnt    NUMBER := 0 ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �ꊇ�o�^����
    -- ====================================================
    FORALL ln_cnt IN 1..gn_cre_idx
      INSERT INTO xxwsh_stock_delivery_info_tmp
        (
          corporation_name                                  -- ��Ж�
         ,data_class                                        -- �f�[�^���
         ,transfer_branch_no                                -- �`���p�}��
         ,delivery_no                                       -- �z��No
         ,request_no                                        -- �˗�No
         ,reserve                                           -- �\��
         ,head_sales_branch                                 -- ���_�R�[�h
         ,head_sales_branch_name                            -- �Ǌ����_����
         ,shipped_locat_code                                -- �o�ɑq�ɃR�[�h
         ,shipped_locat_name                                -- �o�ɑq�ɖ���
         ,ship_to_locat_code                                -- ���ɑq�ɃR�[�h
         ,ship_to_locat_name                                -- ���ɑq�ɖ���
         ,freight_carrier_code                              -- �^���Ǝ҃R�[�h
         ,freight_carrier_name                              -- �^���ƎҖ�
         ,deliver_to                                        -- �z����R�[�h
         ,deliver_to_name                                   -- �z���於
         ,schedule_ship_date                                -- ����
         ,schedule_arrival_date                             -- ����
         ,shipping_method_code                              -- �z���敪
         ,weight                                            -- �d��/�e��
         ,mixed_no                                          -- ���ڌ��˗���
         ,collected_pallet_qty                              -- �p���b�g�������
         ,arrival_time_from                                 -- ���׎��Ԏw��(FROM)
         ,arrival_time_to                                   -- ���׎��Ԏw��(TO)
         ,cust_po_number                                    -- �ڋq�����ԍ�
         ,description                                       -- �E�v
         ,status                                            -- �X�e�[�^�X
         ,freight_charge_class                              -- �^���敪
         ,pallet_sum_quantity                               -- �p���b�g�g�p����
         ,reserve1                                          -- �\���P
         ,reserve2                                          -- �\���Q
         ,reserve3                                          -- �\���R
         ,reserve4                                          -- �\���S
         ,report_dept                                       -- �񍐕���
         ,item_code                                         -- �i�ڃR�[�h
         ,item_name                                         -- �i�ږ�
         ,item_uom_code                                     -- �i�ڒP��
         ,item_quantity                                     -- �i�ڐ���
         ,lot_no                                            -- ���b�g�ԍ�
         ,lot_date                                          -- ������
         ,best_bfr_date                                     -- �ܖ�����
         ,lot_sign                                          -- �ŗL�L��
         ,lot_quantity                                      -- ���b�g����
         ,new_modify_del_class                              -- �f�[�^�敪
         ,update_date                                       -- �X�V����
         ,line_number                                       -- ���הԍ�
         ,data_type                                         -- �f�[�^�^�C�v
         ,eos_shipped_locat                                 -- EOS����i�o�ɑq�Ɂj
         ,eos_freight_carrier                               -- EOS����i�^���Ǝҁj
         ,eos_csv_output                                    -- EOS����iCSV�o�́j
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
         ,notif_date                                        -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
         ,target_request_id                                 -- �v��ID
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
        )
      VALUES
        (
          gt_corporation_name(ln_cnt)             -- ��Ж�
         ,gt_data_class(ln_cnt)                   -- �f�[�^���
         ,gt_transfer_branch_no(ln_cnt)           -- �`���p�}��
         ,gt_delivery_no(ln_cnt)                  -- �z��No
         ,gt_request_no(ln_cnt)                   -- �˗�No
         ,gt_reserve(ln_cnt)                      -- �\��
         ,gt_head_sales_branch(ln_cnt)            -- ���_�R�[�h
         ,gt_head_sales_branch_name(ln_cnt)       -- �Ǌ����_����
         ,gt_shipped_locat_code(ln_cnt)           -- �o�ɑq�ɃR�[�h
         ,gt_shipped_locat_name(ln_cnt)           -- �o�ɑq�ɖ���
         ,gt_ship_to_locat_code(ln_cnt)           -- ���ɑq�ɃR�[�h
         ,gt_ship_to_locat_name(ln_cnt)           -- ���ɑq�ɖ���
         ,gt_freight_carrier_code(ln_cnt)         -- �^���Ǝ҃R�[�h
         ,gt_freight_carrier_name(ln_cnt)         -- �^���ƎҖ�
         ,gt_deliver_to(ln_cnt)                   -- �z����R�[�h
         ,gt_deliver_to_name(ln_cnt)              -- �z���於
         ,gt_schedule_ship_date(ln_cnt)           -- ����
         ,gt_schedule_arrival_date(ln_cnt)        -- ����
         ,gt_shipping_method_code(ln_cnt)         -- �z���敪
         ,gt_weight(ln_cnt)                       -- �d��/�e��
         ,gt_mixed_no(ln_cnt)                     -- ���ڌ��˗���
         ,gt_collected_pallet_qty(ln_cnt)         -- �p���b�g�������
         ,gt_arrival_time_from(ln_cnt)            -- ���׎��Ԏw��(FROM)
         ,gt_arrival_time_to(ln_cnt)              -- ���׎��Ԏw��(TO)
         ,gt_cust_po_number(ln_cnt)               -- �ڋq�����ԍ�
         ,gt_description(ln_cnt)                  -- �E�v
         ,gt_status(ln_cnt)                       -- �X�e�[�^�X
         ,gt_freight_charge_class(ln_cnt)         -- �^���敪
         ,gt_pallet_sum_quantity(ln_cnt)          -- �p���b�g�g�p����
         ,gt_reserve1(ln_cnt)                     -- �\���P
         ,gt_reserve2(ln_cnt)                     -- �\���Q
         ,gt_reserve3(ln_cnt)                     -- �\���R
         ,gt_reserve4(ln_cnt)                     -- �\���S
         ,gt_report_dept(ln_cnt)                  -- �񍐕���
         ,gt_item_code(ln_cnt)                    -- �i�ڃR�[�h
         ,gt_item_name(ln_cnt)                    -- �i�ږ�
         ,gt_item_uom_code(ln_cnt)                -- �i�ڒP��
         ,gt_item_quantity(ln_cnt)                -- �i�ڐ���
         ,gt_lot_no(ln_cnt)                       -- ���b�g�ԍ�
         ,gt_lot_date(ln_cnt)                     -- ������
         ,gt_best_bfr_date(ln_cnt)                -- �ܖ�����
         ,gt_lot_sign(ln_cnt)                     -- �ŗL�L��
         ,gt_lot_quantity(ln_cnt)                 -- ���b�g����
         ,gt_new_modify_del_class(ln_cnt)         -- �f�[�^�敪
         ,gt_update_date(ln_cnt)                  -- �X�V����
         ,gt_line_number(ln_cnt)                  -- ���הԍ�
         ,gt_data_type(ln_cnt)                    -- �f�[�^�^�C�v
         ,gt_eos_shipped_locat(ln_cnt)            -- EOS����i�o�ɑq�Ɂj
         ,gt_eos_freight_carrier(ln_cnt)          -- EOS����i�^���Ǝҁj
         ,gt_eos_csv_output(ln_cnt)               -- EOS����iCSV�o�́j
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
         ,gt_notif_date(ln_cnt)                   -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
         ,gt_target_request_id(ln_cnt)            -- �v��ID
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
        ) ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_ins_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_out_csv_data
   * Description      : �b�r�u�o�͏���(E-08,E-09)
   ************************************************************************************************/
  PROCEDURE prc_out_csv_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_csv_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_lookup_wf_notif    CONSTANT VARCHAR2(100) := 'XXCMN_WF_NOTIFICATION' ;   -- Workflow�ʒm��
    lc_lookup_wf_info     CONSTANT VARCHAR2(100) := 'XXCMN_WF_INFO' ;           -- Workflow���
-- M.Hokkanji Ver1.4 START
    lc_transfer_branch_no_d CONSTANT VARCHAR2(100) := '20' ;    -- ����
-- M.Hokkanji Ver1.4 END
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
    cv_cr         CONSTANT VARCHAR2(1)  := CHR(13); -- ���s�R�[�h
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    -- ���[�N�t���[�֘A
    lv_wf_ope_div       VARCHAR2(100) ;         -- �����敪
    lv_wf_class         VARCHAR2(100) ;         -- �Ώ�
    lv_wf_notification  VARCHAR2(100) ;         -- ����
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;
--
-- ##### 20080611 Ver.1.6 WF�Ή� START #####
    lv_dir              VARCHAR2(150) ;         -- �f�B���N�g��
    lv_file_name        VARCHAR2(150) ;         -- �t�@�C����
-- ##### 20080611 Ver.1.6 WF�Ή� END   #####
--
-- M.Hokkanji Ver1.5 START
    lt_new_modify_del_class xxwsh_stock_delivery_info_tmp.new_modify_del_class%TYPE;
-- M.Hokkanji Ver1.5 END
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    ----------------------------------------
    -- �d�n�r����
    ----------------------------------------
    CURSOR cu_eos_data
    IS
      SELECT DISTINCT xsdit.eos_csv_output
      FROM  xxwsh_stock_delivery_info_tmp    xsdit
-- ##### 20081020 Ver.1.24 ����#417�Ή� START #####
      WHERE xsdit.target_request_id = gn_request_id    -- �v��ID
-- ##### 20081020 Ver.1.24 ����#417�Ή� END   #####
      ORDER BY xsdit.eos_csv_output
    ;
    ----------------------------------------
    -- �d�n�r����
    ----------------------------------------
    CURSOR cu_out_data
      ( p_eos_csv_output    xxwsh_stock_delivery_info_tmp.eos_csv_output%TYPE )
    IS
      SELECT xsdit.corporation_name         -- ��Ж�
            ,xsdit.data_class               -- �f�[�^���
            ,xsdit.transfer_branch_no       -- �`���p�}��
            ,xsdit.delivery_no              -- �z��No
            ,xsdit.request_no               -- �˗�No
            ,xsdit.reserve                  -- �\��
            ,xsdit.head_sales_branch        -- ���_�R�[�h
            ,xsdit.head_sales_branch_name   -- �Ǌ����_����
            ,xsdit.shipped_locat_code       -- �o�ɑq�ɃR�[�h
            ,xsdit.shipped_locat_name       -- �o�ɑq�ɖ���
            ,xsdit.ship_to_locat_code       -- ���ɑq�ɃR�[�h
            ,xsdit.ship_to_locat_name       -- ���ɑq�ɖ���
            ,xsdit.freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,xsdit.freight_carrier_name     -- �^���ƎҖ�
            ,xsdit.deliver_to               -- �z����R�[�h
            ,xsdit.deliver_to_name          -- �z���於
            ,xsdit.schedule_ship_date       -- ����
            ,xsdit.schedule_arrival_date    -- ����
            ,xsdit.shipping_method_code     -- �z���敪
            ,xsdit.weight                   -- �d��/�e��
            ,xsdit.mixed_no                 -- ���ڌ��˗���
            ,xsdit.collected_pallet_qty     -- �p���b�g�������
            ,xsdit.arrival_time_from        -- ���׎��Ԏw��(FROM)
            ,xsdit.arrival_time_to          -- ���׎��Ԏw��(TO)
            ,xsdit.cust_po_number           -- �ڋq�����ԍ�
            ,xsdit.description              -- �E�v
            ,xsdit.status                   -- �X�e�[�^�X
            ,xsdit.freight_charge_class     -- �^���敪
            ,xsdit.pallet_sum_quantity      -- �p���b�g�g�p����
            ,xsdit.reserve1                 -- �\���P
            ,xsdit.reserve2                 -- �\���Q
            ,xsdit.reserve3                 -- �\���R
            ,xsdit.reserve4                 -- �\���S
            ,xsdit.report_dept              -- �񍐕���
            ,xsdit.item_code                -- �i�ڃR�[�h
            ,xsdit.item_name                -- �i�ږ�
            ,xsdit.item_uom_code            -- �i�ڒP��
            ,xsdit.item_quantity            -- �i�ڐ���
            ,xsdit.lot_no                   -- ���b�g�ԍ�
            ,xsdit.lot_date                 -- ������
            ,xsdit.best_bfr_date            -- �ܖ�����
            ,xsdit.lot_sign                 -- �ŗL�L��
            ,xsdit.lot_quantity             -- ���b�g����
            ,xsdit.new_modify_del_class     -- �f�[�^�敪
            ,xsdit.update_date              -- �X�V����
            ,xsdit.line_number              -- ���הԍ�
            ,xsdit.data_type                -- �f�[�^�^�C�v
            ,xsdit.eos_shipped_locat        -- EOS����i�o�ɑq�Ɂj
            ,xsdit.eos_freight_carrier      -- EOS����i�^���Ǝҁj
            ,xsdit.eos_csv_output           -- EOS����iCSV�o�́j
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,xsdit.notif_date               -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
      FROM xxwsh_stock_delivery_info_tmp    xsdit
      WHERE xsdit.eos_csv_output = p_eos_csv_output
-- ##### 20081020 Ver.1.24 ����#417�Ή� START #####
      AND  xsdit.target_request_id = gn_request_id    -- �v��ID
-- ##### 20081020 Ver.1.24 ����#417�Ή� END   #####
      ORDER BY xsdit.new_modify_del_class   DESC    -- �f�[�^�敪   �i�~���j
              ,xsdit.data_type                      -- �f�[�^�^�C�v �i�����j
              ,xsdit.data_class                     -- �f�[�^���   �i�����j
              ,xsdit.request_no                     -- �˗�No       �i�����j
              ,xsdit.transfer_branch_no             -- �`���p�}��   �i�����j
              ,xsdit.line_number                    -- ���הԍ�     �i�����j
    ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �d�n�r����i�b�r�u�j�f�[�^���o
    -- ====================================================
    <<eos_loop>>
    FOR re_eos_data IN cu_eos_data LOOP
--
      -- ====================================================
      -- �o�̓f�[�^���o
      -- ====================================================
      <<out_loop>>
      FOR re_out_data IN cu_out_data
        ( p_eos_csv_output => re_eos_data.eos_csv_output ) LOOP
-- M.Hokkanji Ver1.4 START
        IF (re_out_data.transfer_branch_no = lc_transfer_branch_no_d ) THEN
          lt_new_modify_del_class := re_out_data.new_modify_del_class;
        ELSE
          lt_new_modify_del_class := NULL;
        END IF;
-- M.Hokkanji Ver1.4 END
--
-- ##### 20080611 Ver.1.6 WF�Ή� START #####
--
        -- ====================================================
        -- �t�@�C��OPEN �`�F�b�N
        -- ====================================================
        IF ( UTL_FILE.IS_OPEN(lf_file_hand) = FALSE) THEN
--
          -------------------------------------------------------
          -- ���[�N�t���[���擾�F�����敪
          -------------------------------------------------------
          lv_wf_ope_div := gc_wf_ope_div;
--
          -------------------------------------------------------
          -- ���[�N�t���[���擾�F�Ώ�
          -------------------------------------------------------
          -- EOS����iCSV�o�́j�� EOS����i�o�ɑq�Ɂj�̏ꍇ
          IF ( re_out_data.eos_csv_output = re_out_data.eos_shipped_locat ) THEN
            -- �O���q��
            lv_wf_class := gc_wf_class_gai ;
--
          -- EOS����iCSV�o�́j�� EOS����i�o�ɑq�Ɂj�̏ꍇ
          ELSE
            -- �^���Ǝ�
            lv_wf_class := gc_wf_class_uns ;
          END IF ;
--
          -------------------------------------------------------
          -- ���[�N�t���[���擾�F����
          -------------------------------------------------------
          lv_wf_notification := re_out_data.eos_csv_output;
--
          -------------------------------------------------------
          -- ���[�N�t���[�֘A���擾
          -------------------------------------------------------
          xxwsh_common3_pkg.get_wsh_wf_info(  
                            iv_wf_ope_div       => lv_wf_ope_div      -- �����敪
                          , iv_wf_class         => lv_wf_class        -- �Ώ�
                          , iv_wf_notification  => lv_wf_notification -- ����
                          , or_wf_whs_rec       => gr_wf_whs_rec      -- �t�@�C�����
                          , ov_errbuf           => lv_errbuf          -- �G���[�E���b�Z�[�W
                          , ov_retcode          => lv_retcode         -- ���^�[���E�R�[�h
                          , ov_errmsg           => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W
          IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_api_expt;
          END IF ;
--
          -------------------------------------------------------
          -- �t�@�C���o�͏��ݒ�
          -------------------------------------------------------
          -- �f�B���N�g��
          lv_dir        :=  gr_wf_whs_rec.directory;
          -- �t�@�C�����i�����敪'-'EOS����'_'YYYYMMDDHH24MISS'_'�N�C�b�N�R�[�h�t�@�C�����j
          lv_file_name  :=  lv_wf_ope_div               || '-' || 
                            re_out_data.eos_csv_output  || '_' || 
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
--                            gv_filetimes                || '_' ||
                            gv_filetimes                ||
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
                            gr_wf_whs_rec.file_name ;
--
-- ##### 20081112 Ver.1.27 ����#626�Ή� START #####
          -- WF�I�[�i�[���N�����[�U�֕ύX
          gr_wf_whs_rec.wf_owner := gv_exec_user;
-- ##### 20081112 Ver.1.27 ����#626�Ή� END   #####
--
          -------------------------------------------------------
          -- �t�s�k�t�@�C���I�[�v��
          -------------------------------------------------------
          lf_file_hand := UTL_FILE.FOPEN( lv_dir         -- �f�B���N�g��
                                         ,lv_file_name  -- �t�@�C����
                                         ,'w') ;        -- ���[�h�i�㏑�j
--
        END IF;
-- ##### 20080611 Ver.1.6 WF�Ή� END   #####
--
        -- ====================================================
        -- �o�͕�����ҏW
        -- ====================================================
        lv_csv_text := re_out_data.corporation_name         || ','    -- ��Ж�
                    || re_out_data.data_class               || ','    -- �f�[�^���
                    || re_out_data.transfer_branch_no       || ','    -- �`���p�}��
                    || re_out_data.delivery_no              || ','    -- �z��No
                    || re_out_data.request_no               || ','    -- �˗�No
                    || re_out_data.reserve                  || ','    -- �\��
                    || re_out_data.head_sales_branch        || ','    -- ���_�R�[�h
                    || REPLACE(re_out_data.head_sales_branch_name,',') || ','    -- �Ǌ����_����
                    || re_out_data.shipped_locat_code       || ','    -- �o�ɑq�ɃR�[�h
                    || REPLACE(re_out_data.shipped_locat_name,',')     || ','    -- �o�ɑq�ɖ���
                    || re_out_data.ship_to_locat_code       || ','    -- ���ɑq�ɃR�[�h
                    || REPLACE(re_out_data.ship_to_locat_name,',')     || ','    -- ���ɑq�ɖ���
                    || re_out_data.freight_carrier_code     || ','    -- �^���Ǝ҃R�[�h
                    || REPLACE(re_out_data.freight_carrier_name,',')   || ','    -- �^���ƎҖ�
                    || re_out_data.deliver_to               || ','    -- �z����R�[�h
                    || REPLACE(re_out_data.deliver_to_name,',')        || ','    -- �z���於
                    || TO_CHAR( re_out_data.schedule_ship_date   , 'YYYY/MM/DD' ) || ','
                    || TO_CHAR( re_out_data.schedule_arrival_date, 'YYYY/MM/DD' ) || ','
                    || re_out_data.shipping_method_code     || ','    -- �z���敪
                    --|| re_out_data.weight                   || ','    -- �d��/�e�� --2008/08/12 Del �ۑ�#48(�ύX#164)
                    || CEIL(TRUNC(re_out_data.weight,3))    || ','    -- �d��/�e��   --2008/08/12 Add �ۑ�#48(�ύX#164)
                    || re_out_data.mixed_no                 || ','    -- ���ڌ��˗���
                    || re_out_data.collected_pallet_qty     || ','    -- �p���b�g�������
                    || re_out_data.arrival_time_from        || ','    -- ���׎��Ԏw��(FROM)
                    || re_out_data.arrival_time_to          || ','    -- ���׎��Ԏw��(TO)
                    || re_out_data.cust_po_number           || ','    -- �ڋq�����ԍ�
                    || REPLACE(re_out_data.description,',')            || ','    -- �E�v
                    || re_out_data.status                   || ','    -- �X�e�[�^�X
                    || re_out_data.freight_charge_class     || ','    -- �^���敪
                    || re_out_data.pallet_sum_quantity      || ','    -- �p���b�g�g�p����
                    || re_out_data.reserve1                 || ','    -- �\���P
                    || re_out_data.reserve2                 || ','    -- �\���Q
                    || re_out_data.reserve3                 || ','    -- �\���R
                    || re_out_data.reserve4                 || ','    -- �\���S
                    || re_out_data.report_dept              || ','    -- �񍐕���
                    || re_out_data.item_code                || ','    -- �i�ڃR�[�h
                    || REPLACE(re_out_data.item_name,',')              || ','    -- �i�ږ�
                    || re_out_data.item_uom_code            || ','    -- �i�ڒP��
                    --|| re_out_data.item_quantity            || ','    -- �i�ڐ��� --2008/08/12 Del �ۑ�#32
                    || CEIL(TRUNC(re_out_data.item_quantity,3)) || ','  -- �i�ڐ��� --2008/08/12 Add �ۑ�#32
                    || re_out_data.lot_no                   || ','    -- ���b�g�ԍ�
                    || TO_CHAR( re_out_data.lot_date     , 'YYYY/MM/DD' ) || ','
                    || TO_CHAR( re_out_data.best_bfr_date, 'YYYY/MM/DD' ) || ','
                    || re_out_data.lot_sign                 || ','    -- �ŗL�L��
                    --|| re_out_data.lot_quantity             || ','    -- ���b�g���� --2008/08/12 Del �ۑ�#32
                    || CEIL(TRUNC(re_out_data.lot_quantity,3)) || ','   -- ���b�g���� --2008/08/12 Add �ۑ�#32
-- M.Hokkanji Ver1.4 STRAT
                    || lt_new_modify_del_class              || ','    -- �f�[�^�敪
--                    || re_out_data.new_modify_del_class     || ','    -- �f�[�^�敪
--
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
--                    || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' );
                    || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' )
                    || cv_cr;                                         -- ���s�R�[�h(CR)
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
--
--                    || TO_CHAR( re_out_data.update_date, 'YYYY/MM/DD HH24:MI:SS' ) || ','
--                    || re_out_data.line_number              || ','    -- ���הԍ�
--                    || re_out_data.data_type                || ','    -- �f�[�^�^�C�v
--                    || re_out_data.eos_shipped_locat        || ','    -- EOS����i�o�ɑq�Ɂj
--                    || re_out_data.eos_freight_carrier      || ','    -- EOS����i�^���Ǝҁj
--                    || re_out_data.eos_csv_output                     -- EOS����iCSV�o�́j
--                    ;
-- M.Hokkanji Ver1.4 END
--
        -- ====================================================
        -- �b�r�u�o��
        -- ====================================================
        UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- ���������J�E���g�A�b�v
        -- ====================================================
        -------------------------------------------------------
        -- �o�׃f�[�^
        -------------------------------------------------------
        IF ( re_out_data.data_type IN( gc_data_type_syu_ins
                                      ,gc_data_type_syu_can ) ) THEN
          gn_out_cnt_syu := gn_out_cnt_syu + 1 ;
--
        -------------------------------------------------------
        -- �x���f�[�^
        -------------------------------------------------------
        ELSIF ( re_out_data.data_type IN( gc_data_type_shi_ins
                                         ,gc_data_type_shi_can ) ) THEN
          gn_out_cnt_shi := gn_out_cnt_shi + 1 ;
--
        -------------------------------------------------------
        -- �ړ��f�[�^
        -------------------------------------------------------
        ELSE
          gn_out_cnt_mov := gn_out_cnt_mov + 1 ;
--
        END IF ;
--
      END LOOP out_loop ;
--
      -- ====================================================
      -- �t�s�k�t�@�C���N���[�Y
      -- ====================================================
      UTL_FILE.FCLOSE( lf_file_hand ) ;
--
-- ##### 20080611 Ver.1.6 WF�Ή� START #####
      -- ====================================================
      -- ���[�N�t���[�ʒm
      -- ====================================================
      xxwsh_common3_pkg.wf_whs_start( 
                    ir_wf_whs_rec => gr_wf_whs_rec      -- ���[�N�t���[�֘A���
                   ,iv_filename   => lv_file_name       -- �t�@�C����
                   ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W
                   ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h
                   ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF ;
-- ##### 20080611 Ver.1.6 WF�Ή� END   #####
--
-- ##### 20081023 Ver.1.25 T_S_440�Ή� START #####
      -- ====================================================
      -- �ʒm����쐬
      -- ====================================================
      -- �����C���N�������g
      gn_notif_idx := gn_notif_idx + 1;
--
      -- EOS����ݒ�(EOS�̌��ɕ������̂��ߑS�pSPASE�ݒ�)
      gt_notif_msg(gn_notif_idx) := gr_wf_whs_rec.wf_notification || '�@�@�@�@';
--
      -- �ʒm��ݒ�
      IF (gr_wf_whs_rec.user_cd01 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || gr_wf_whs_rec.user_cd01;
      END IF;
      IF (gr_wf_whs_rec.user_cd02 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd02;
      END IF;
      IF (gr_wf_whs_rec.user_cd03 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd03;
      END IF;
      IF (gr_wf_whs_rec.user_cd04 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd04;
      END IF;
      IF (gr_wf_whs_rec.user_cd05 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd05;
      END IF;
      IF (gr_wf_whs_rec.user_cd06 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd06;
      END IF;
      IF (gr_wf_whs_rec.user_cd07 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd07;
      END IF;
      IF (gr_wf_whs_rec.user_cd08 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd08;
      END IF;
      IF (gr_wf_whs_rec.user_cd09 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd09;
      END IF;
      IF (gr_wf_whs_rec.user_cd10 IS NOT NULL ) THEN
        gt_notif_msg(gn_notif_idx) := gt_notif_msg(gn_notif_idx) || ',' || gr_wf_whs_rec.user_cd10;
      END IF;
-- ##### 20081023 Ver.1.25 T_S_440�Ή� END   #####
--
    END LOOP eos_loop ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
-- M.HOKKANJI Ver1.3 START
--      UTL_FILE.FCLOSE_ALL ;
      IF ( UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
-- M.HOKKANJI Ver1.3 END
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- M.HOKKANJI Ver1.3 START
--      UTL_FILE.FCLOSE_ALL ;
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
-- M.HOKKANJI Ver1.3 END
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- M.HOKKANJI Ver1.3 START
--      UTL_FILE.FCLOSE_ALL ;
      IF ( UTL_FILE.IS_OPEN(lf_file_hand) ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
-- M.HOKKANJI Ver1.3 END
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_out_csv_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_out_data
   * Description      : �ʒm�ς݃f�[�^�o�^����(E-11,E-12)
   ************************************************************************************************/
  PROCEDURE prc_ins_out_data
    (
      ov_errbuf               OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode              OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg               OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_out_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--###########################  �Œ蕔 END   ####################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_msg_code     CONSTANT VARCHAR2(50) := 'APP-XXWSH-12853' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
--
    -- ==================================================
    -- �J�[�\���錾
    -- ==================================================
    ----------------------------------------
    -- �폜�Ώۃf�[�^
    ----------------------------------------
    CURSOR cu_del_data
    IS
      SELECT xndi.request_no
      FROM xxwsh_notif_delivery_info    xndi
      WHERE xndi.request_no IN
        ( SELECT DISTINCT xsdit.request_no
          FROM   xxwsh_stock_delivery_info_tmp    xsdit
          WHERE  xsdit.new_modify_del_class = gc_data_class_del 
-- ##### 20081020 Ver.1.24 ����#417�Ή� START #####
          AND  xsdit.target_request_id = gn_request_id)    -- �v��ID
-- ##### 20081020 Ver.1.24 ����#417�Ή� END   #####
      FOR UPDATE NOWAIT
    ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���b�N�擾�E�ύX�O�f�[�^�폜
    -- ====================================================
    <<delete_loop>>
    FOR re_del_data IN cu_del_data LOOP
      DELETE
      FROM xxwsh_notif_delivery_info xndi
      WHERE xndi.request_no = re_del_data.request_no
      ;
    END LOOP delete_loop ;
--
    -- ====================================================
    -- �b�r�u�o�̓f�[�^�o�^
    -- ====================================================
    INSERT INTO xxwsh_notif_delivery_info
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            (   notif_delivery_info_id    -- �ʒm�ϓ��o�ɔz���v����ID
              , corporation_name          -- ��Ж�
              , data_class                -- �f�[�^���
              , transfer_branch_no        -- �`���p�}��
              , delivery_no               -- �z��No
              , request_no                -- �˗�No
              , reserve                   -- �\��
              , head_sales_branch         -- ���_�R�[�h
              , head_sales_branch_name    -- �Ǌ����_����
              , shipped_locat_code        -- �o�ɑq�ɃR�[�h
              , shipped_locat_name        -- �o�ɑq�ɖ���
              , ship_to_locat_code        -- ���ɑq�ɃR�[�h
              , ship_to_locat_name        -- ���ɑq�ɖ���
              , freight_carrier_code      -- �^���Ǝ҃R�[�h
              , freight_carrier_name      -- �^���ƎҖ�
              , deliver_to                -- �z����R�[�h
              , deliver_to_name           -- �z���於
              , schedule_ship_date        -- ����
              , schedule_arrival_date     -- ����
              , shipping_method_code      -- �z���敪
              , weight                    -- �d��/�e��
              , mixed_no                  -- ���ڌ��˗���
              , collected_pallet_qty      -- �p���b�g�������
              , arrival_time_from         -- ���׎��Ԏw��(FROM)
              , arrival_time_to           -- ���׎��Ԏw��(TO)
              , cust_po_number            -- �ڋq�����ԍ�
              , description               -- �E�v
              , status                    -- �X�e�[�^�X
              , freight_charge_class      -- �^���敪
              , pallet_sum_quantity       -- �p���b�g�g�p����
              , reserve1                  -- �\���P
              , reserve2                  -- �\���Q
              , reserve3                  -- �\���R
              , reserve4                  -- �\���S
              , report_dept               -- �񍐕���
              , item_code                 -- �i�ڃR�[�h
              , item_name                 -- �i�ږ�
              , item_uom_code             -- �i�ڒP��
              , item_quantity             -- �i�ڐ���
              , lot_no                    -- ���b�g�ԍ�
              , lot_date                  -- ������
              , best_bfr_date             -- �ܖ�����
              , lot_sign                  -- �ŗL�L��
              , lot_quantity              -- ���b�g����
              , new_modify_del_class      -- �f�[�^�敪
              , update_date               -- �X�V����
              , line_number               -- ���הԍ�
              , data_type                 -- �f�[�^�^�C�v
              , eos_shipped_locat         -- EOS����(�o�ɑq��)
              , eos_freight_carrier       -- EOS����(�^���Ǝ�)
              , eos_csv_output            -- EOS����(CSV�o��)
              , notif_date                -- �m��ʒm���{����
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
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
      SELECT xxwsh_notif_delivery_info_s1.NEXTVAL   -- �ʒm�ϓ��o�ɔz���v����ID
            ,corporation_name         -- ��Ж�
            ,data_class               -- �f�[�^���
            ,transfer_branch_no       -- �`���p�}��
            ,delivery_no              -- �z��No
            ,request_no               -- �˗�No
            ,reserve                  -- �\��
            ,head_sales_branch        -- ���_�R�[�h
            ,head_sales_branch_name   -- �Ǌ����_����
            ,shipped_locat_code       -- �o�ɑq�ɃR�[�h
            ,shipped_locat_name       -- �o�ɑq�ɖ���
            ,ship_to_locat_code       -- ���ɑq�ɃR�[�h
            ,ship_to_locat_name       -- ���ɑq�ɖ���
            ,freight_carrier_code     -- �^���Ǝ҃R�[�h
            ,freight_carrier_name     -- �^���ƎҖ�
            ,deliver_to               -- �z����R�[�h
            ,deliver_to_name          -- �z���於
            ,schedule_ship_date       -- ����
            ,schedule_arrival_date    -- ����
            ,shipping_method_code     -- �z���敪
            ,weight                   -- �d��/�e��
            ,mixed_no                 -- ���ڌ��˗���
            ,collected_pallet_qty     -- �p���b�g�������
            ,arrival_time_from        -- ���׎��Ԏw��(FROM)
            ,arrival_time_to          -- ���׎��Ԏw��(TO)
            ,cust_po_number           -- �ڋq�����ԍ�
            ,description              -- �E�v
            ,status                   -- �X�e�[�^�X
            ,freight_charge_class     -- �^���敪
            ,pallet_sum_quantity      -- �p���b�g�g�p����
            ,reserve1                 -- �\���P
            ,reserve2                 -- �\���Q
            ,reserve3                 -- �\���R
            ,reserve4                 -- �\���S
            ,report_dept              -- �񍐕���
            ,item_code                -- �i�ڃR�[�h
            ,item_name                -- �i�ږ�
            ,item_uom_code            -- �i�ڒP��
            ,item_quantity            -- �i�ڐ���
            ,lot_no                   -- ���b�g�ԍ�
            ,lot_date                 -- ������
            ,best_bfr_date            -- �ܖ�����
            ,lot_sign                 -- �ŗL�L��
            ,lot_quantity             -- ���b�g����
            ,new_modify_del_class     -- �f�[�^�敪
            ,update_date              -- �X�V����
            ,line_number              -- ���הԍ�
            ,data_type                -- �f�[�^�^�C�v
            ,eos_shipped_locat        -- EOS����i�o�ɑq�Ɂj
            ,eos_freight_carrier      -- EOS����i�^���Ǝҁj
            ,eos_csv_output           -- EOS����iCSV�o�́j
-- ##### 20080925 Ver.1.20 ����#26�Ή� START #####
            ,notif_date               -- �m��ʒm���{����
-- ##### 20080925 Ver.1.20 ����#26�Ή� END   #####
            ,gn_created_by               -- �쐬��
            ,SYSDATE                     -- �쐬��
            ,gn_last_updated_by          -- �ŏI�X�V��
            ,SYSDATE                     -- �ŏI�X�V��
            ,gn_last_update_login        -- �ŏI�X�V���O�C��
            ,gn_request_id               -- �v��ID
            ,gn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,gn_program_id               -- �R���J�����g�E�v���O����ID
            ,SYSDATE                     -- �v���O�����X�V��
      FROM xxwsh_stock_delivery_info_tmp    xsdit
      WHERE xsdit.new_modify_del_class = gc_data_class_ins
-- ##### 20081020 Ver.1.24 ����#417�Ή� START #####
      AND  xsdit.target_request_id     = gn_request_id    -- �v��ID
-- ##### 20081020 Ver.1.24 ����#417�Ή� END   #####
    ;
--
  EXCEPTION
    -- =============================================================================================
    -- ���b�N�擾�G���[
    -- =============================================================================================
    WHEN ex_lock_error THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := xxcmn_common_pkg.get_msg
                      (
                        iv_application    => gc_appl_sname_wsh
                       ,iv_name           => lc_msg_code
                      ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_ins_out_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_dept_code_01     IN  VARCHAR2          -- 01 : ����_01
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : ����_02(2008/07/16 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : ����_03(2008/07/16 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : ����_04(2008/07/16 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : ����_05(2008/07/16 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : ����_06(2008/07/16 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : ����_07(2008/07/16 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : ����_08(2008/07/16 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : ����_09(2008/07/16 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : ����_10(2008/07/16 Add)
     ,iv_fix_class        IN  VARCHAR2          -- 11 : �\��m��敪
     ,iv_date_cutoff      IN  VARCHAR2          -- 12 : ���ߎ��{��
     ,iv_cutoff_from      IN  VARCHAR2          -- 13 : ���ߎ��{����From
     ,iv_cutoff_to        IN  VARCHAR2          -- 14 : ���ߎ��{����To
     ,iv_date_fix         IN  VARCHAR2          -- 15 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2          -- 16 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2          -- 17 : �m��ʒm���{����To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
     ,iv_ship_date_from   IN  VARCHAR2          -- 18 : �o�ɓ�From
     ,iv_ship_date_to     IN  VARCHAR2          -- 19 : �o�ɓ�To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
     ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W
     ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h
     ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
    lc_msg_code       CONSTANT VARCHAR2(30) := 'APP-XXWSH-11856' ;
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
    -- ==================================================
    -- ���[�J���ϐ�
    -- ==================================================
    lv_temp_request_no    xxwsh_stock_delivery_info_tmp2.request_no%TYPE := '*' ;
    lv_break_flg          VARCHAR2(1) := gc_yes_no_n ;
    lv_error_flg          VARCHAR2(1) := gc_yes_no_n ;
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
    lv_main_data_flg      VARCHAR2(1) := gc_yes_no_n ;
    lv_can_data_flg       VARCHAR2(1) := gc_yes_no_n ;
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
    lv_zero_can_data_flg  VARCHAR2(1) := gc_yes_no_n ;
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
--
    lv_errbuf             VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    -- �x�������p �o�b�t�@
    lv_errbuf2            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_errmsg2            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
    -- ==================================================
    -- ��O�錾
    -- ==================================================
    ex_worn               EXCEPTION ;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
    ov_retcode := gv_status_normal;
--###########################  �Œ蕔 END   ############################
--
    -- =============================================================================================
    -- ��������
    -- =============================================================================================
    --------------------------------------------------
    -- �O���[�o���ϐ��̏�����
    --------------------------------------------------
    gn_out_cnt_syu := 0 ;   -- �o�͌����F�o��
    gn_out_cnt_shi := 0 ;   -- �o�͌����F�x��
    gn_out_cnt_mov := 0 ;   -- �o�͌����F�ړ�
--
    --------------------------------------------------
    -- �p�����[�^�i�[
    --------------------------------------------------
    gr_param.dept_code_01 := iv_dept_code_01 ;                      -- 01 : ����_01
    gr_param.dept_code_02 := iv_dept_code_02 ;                      -- 02 : ����_02(2008/07/16 Add)
    gr_param.dept_code_03 := iv_dept_code_03 ;                      -- 03 : ����_03(2008/07/16 Add)
    gr_param.dept_code_04 := iv_dept_code_04 ;                      -- 04 : ����_04(2008/07/16 Add)
    gr_param.dept_code_05 := iv_dept_code_05 ;                      -- 05 : ����_05(2008/07/16 Add)
    gr_param.dept_code_06 := iv_dept_code_06 ;                      -- 06 : ����_06(2008/07/16 Add)
    gr_param.dept_code_07 := iv_dept_code_07 ;                      -- 07 : ����_07(2008/07/16 Add)
    gr_param.dept_code_08 := iv_dept_code_08 ;                      -- 08 : ����_08(2008/07/16 Add)
    gr_param.dept_code_09 := iv_dept_code_09 ;                      -- 09 : ����_09(2008/07/16 Add)
    gr_param.dept_code_10 := iv_dept_code_10 ;                      -- 10 : ����_10(2008/07/16 Add)
    gr_param.fix_class   := iv_fix_class ;                          -- 11 : �\��m��敪
    gr_param.date_cutoff := SUBSTR( iv_date_cutoff, 1, 10 ) ;       -- 12 : ���ߎ��{��
    gr_param.cutoff_from := NVL( iv_cutoff_from, gc_time_min ) ;    -- 13 : ���ߎ��{����From
    gr_param.cutoff_to   := NVL( iv_cutoff_to  , gc_time_max ) ;    -- 14 : ���ߎ��{����To
    gr_param.date_fix    := SUBSTR( iv_date_fix   , 1, 10 ) ;       -- 15 : �m��ʒm���{��
    gr_param.fix_from    := NVL( iv_fix_from, gc_time_min ) ;       -- 16 : �m��ʒm���{����From
    gr_param.fix_to      := NVL( iv_fix_to  , gc_time_max ) ;       -- 17 : �m��ʒm���{����To
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    -- ���d�N���m�F�p�i���Ԃɕb������O�ɐݒ�j
    gv_date_fix :=  iv_date_fix;        -- �m��ʒm���{��
    gv_fix_from :=  gr_param.fix_from;  -- �m��ʒm���{����From
    gv_fix_to   :=  gr_param.fix_to;    -- �m��ʒm���{����To
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
    gr_param.cutoff_from := ' ' || gr_param.cutoff_from || ':00' ;
    gr_param.cutoff_to   := ' ' || gr_param.cutoff_to   || ':00' ;
    gr_param.fix_from    := ' ' || gr_param.fix_from    || ':00' ;
    gr_param.fix_to      := ' ' || gr_param.fix_to      || ':00' ;
--
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
    gr_param.ship_date_from := SUBSTR(iv_ship_date_from, 1, 10) ;   -- �o�ɓ�From
    gr_param.ship_date_to   := SUBSTR(iv_ship_date_to,   1, 10) ;   -- �o�ɓ�To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
    --------------------------------------------------
    -- �v�g�n�J�����擾
    --------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- �쐬��
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- �b�o�E�A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- �R���J�����g�E�v���O����ID
--
    -- =============================================================================================
    -- E-01 �p�����[�^�`�F�b�N
    -- =============================================================================================
    prc_chk_param
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- =============================================================================================
    -- E-02 �v���t�@�C���擾
    -- =============================================================================================
    prc_get_profile
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    -- �\��m��敪�F�m�� �̏ꍇ
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN
      -- ===========================================================================================
      -- ���d�N���`�F�b�N
      -- ===========================================================================================
      prc_chk_multi
        (
          ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
        RAISE global_process_expt;
      END IF ;
    END IF;
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
    -- =============================================================================================
    -- E-03 �f�[�^�폜
    -- =============================================================================================
    prc_del_temp_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- =============================================================================================
    -- ���ԃe�[�u���o�^
    -- =============================================================================================
    prc_ins_temp_table
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- =============================================================================================
    -- E-04 ���C���f�[�^���o
    -- =============================================================================================
    prc_get_main_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    -- �G���[������
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
--
    -- �x��������
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      gn_warn_cnt := gn_warn_cnt + 1 ;
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
--      RAISE ex_worn ;
      lv_main_data_flg := gc_yes_no_y;
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
    END IF ;
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
--
    -- �\��m��敪�F�m�� �̏ꍇ
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN
      -- ===========================================================================================
      --  ����f�[�^���o
      -- ===========================================================================================
      prc_get_can_data
        (
          ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg
        ) ;
      -- �G���[������
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
        RAISE global_process_expt;
      -- �x��������
      ELSIF ( lv_retcode = gv_status_warn ) THEN
        gn_warn_cnt := gn_warn_cnt + 1 ;
        -- ����f�[�^���o �f�[�^�Ȃ�
        lv_can_data_flg := gc_yes_no_y;
      END IF ;
--
    -- �\��m��敪�F�\�� �̏ꍇ
    ELSE
      -- �\��̏ꍇ�͒��o���Ȃ��̂ŁA�f�[�^���𖳏����ɐݒ�
      lv_can_data_flg := gc_yes_no_y;
    END IF ;
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
--
    -- �\��m��敪�F�m�� �̏ꍇ
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN
      -- ===========================================================================================
      --  ����f�[�^���o
      -- ===========================================================================================
      prc_get_zero_can_data
        (
          ov_errbuf   => lv_errbuf
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg
        ) ;
      -- �G���[������
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
        RAISE global_process_expt;
      -- �x��������
      ELSIF ( lv_retcode = gv_status_warn ) THEN
        gn_warn_cnt := gn_warn_cnt + 1 ;
        -- ����f�[�^���o �f�[�^�Ȃ�
        lv_zero_can_data_flg := gc_yes_no_y;
      END IF ;
--
    -- �\��m��敪�F�\�� �̏ꍇ
    ELSE
      -- �\��̏ꍇ�͒��o���Ȃ��̂ŁA�f�[�^���𖳏����ɐݒ�
      lv_zero_can_data_flg := gc_yes_no_y;
    END IF ;
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
--
    -- ���C���f�[�^���o�A����f�[�^���o�A���א��ʂO�̎���f�[�^���o
    -- �ŋ��Ƀf�[�^�����݂��Ȃ��ꍇ
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
--    IF ((lv_main_data_flg = gc_yes_no_y) 
--      AND (lv_can_data_flg = gc_yes_no_y)) THEN
    IF ((lv_main_data_flg       = gc_yes_no_y) 
      AND (lv_can_data_flg      = gc_yes_no_y)
      AND (lv_zero_can_data_flg = gc_yes_no_y)) THEN
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
      -- �f�[�^�Ȃ����b�Z�[�W
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                      ,iv_name          => lc_msg_code
                    ) ;
      lv_errbuf  := lv_errmsg;
      RAISE ex_worn ;
    END IF;
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
    -- ���C���f�[�^�����݂����ꍇ�̂ݒʒm���쐬����
    IF (lv_main_data_flg = gc_yes_no_n) THEN
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
    <<main_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      gn_target_cnt := gn_target_cnt + 1 ;
--
      ----------------------------------------------------------------------------------------------
      -- �˗��m���u���C�N�t���O�̐ݒ�
      ----------------------------------------------------------------------------------------------
      IF ( lv_temp_request_no = gt_main_data(i).request_no ) THEN
        lv_break_flg := gc_yes_no_n ;
      ELSE
        lv_break_flg       := gc_yes_no_y ;
        lv_error_flg       := gc_yes_no_n ;
        lv_temp_request_no := gt_main_data(i).request_no ;
      END IF ;
--
      -- ===========================================================================================
      -- E-05 �ʒm�Ϗ��쐬����
      -- ===========================================================================================
      IF (   ( lv_error_flg                     = gc_yes_no_n             )         -- �G���[����
         AND ( gt_main_data(i).data_type       IN( gc_data_type_syu_ins             -- �o�ׁF�o�^
                                                  ,gc_data_type_shi_ins             -- �x���F�o�^
                                                  ,gc_data_type_mov_ins ) ) ) THEN  -- �ړ��F�o�^
        prc_create_ins_data
          (
            in_idx        => i
           ,iv_break_flg  => lv_break_flg
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
--
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          gn_wrm_idx              := gn_wrm_idx + 1 ;
          gt_worm_msg(gn_wrm_idx) := lv_errmsg ;
--
          lv_error_flg := gc_yes_no_y ;
--
        END IF ;
--
      END IF ;
--
      -- ===========================================================================================
      -- E-06 �ύX�O������f�[�^�쐬����
      -- ===========================================================================================
      IF (   ( lv_error_flg                      = gc_yes_no_n       )    -- �G���[����
         AND ( lv_break_flg                      = gc_yes_no_y       )    -- �˗��m���u���C�N
         AND ( gr_param.fix_class                = gc_fix_class_k    )    -- �\��m��敪�F�m��
         AND ( gt_main_data(i).prev_notif_status = gc_notif_status_r )    -- �O��ʒm�r�s�F�Ēʒm�v
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� START #####
/***** �Ēʒm�v�̏ꍇ�͓o�^����Ă���A�������Œʒm�ςݑS�Ăɑ΂��āA����̃f�[�^���쐬����
         AND ( gt_main_data(i).eos_shipped_locat   IS NOT NUll )          -- �o�d�n�r����FNOT NULL
*****/
-- ##### 20080919 Ver.1.18 T_S_453 460 468�Ή� END   #####
-- M.Hokkanji Ver1.5 START
             ) THEN
--         AND ( gt_main_data(i).eos_freight_carrier IS NOT NUll ) ) THEN   -- �^�d�n�r����FNOT NULL
-- M.Hokkanji Ver1.5 END
        prc_create_can_data
          (
            iv_request_no           => gt_main_data(i).request_no
           ,iv_eos_shipped_locat    => gt_main_data(i).eos_shipped_locat
           ,iv_eos_freight_carrier  => gt_main_data(i).eos_freight_carrier
           ,ov_errbuf               => lv_errbuf
           ,ov_retcode              => lv_retcode
           ,ov_errmsg               => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
--
      END IF ;
--
    END LOOP main_loop ;
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
    END IF;
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� START #####
--
    -- ����f�[�^�����݂����ꍇ�̂ݎ���f�[�^�쐬���������s����
    IF (( gr_param.fix_class  =   gc_fix_class_k)       -- �\��m��敪�F�m��
      AND  ( lv_can_data_flg  =   gc_yes_no_n )) THEN   -- ����f�[�^�����݂���ꍇ
--
      -- ===========================================================================================
      -- E-06 �ύX�O������f�[�^�쐬�����i����f�[�^���o�ł̑Ώۃf�[�^�j
      -- ===========================================================================================
      <<can_loop>>
      FOR i IN 1..gt_can_data.COUNT LOOP
--
        prc_create_can_data
          (
            iv_request_no           => gt_can_data(i).request_no -- �˗�No
            ,iv_eos_shipped_locat   => NULL                      -- �g�p���Ȃ�����NULL
            ,iv_eos_freight_carrier => NULL                      -- �g�p���Ȃ�����NULL
            ,ov_errbuf              => lv_errbuf
            ,ov_retcode             => lv_retcode
            ,ov_errmsg              => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
--
      END LOOP can_loop ;
--
    END IF ;
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� START #####
--
    -- �˗����ʃ[������f�[�^���o�̎���f�[�^�����݂����ꍇ�̂ݎ���f�[�^�쐬���������s����
    IF (( gr_param.fix_class  =   gc_fix_class_k)       -- �\��m��敪�F�m��
      AND  ( lv_zero_can_data_flg  =   gc_yes_no_n )) THEN   -- �˗����ʃ[������f�[�^�����݂���ꍇ
--
      -- ===========================================================================================
      -- E-06 �ύX�O������f�[�^�쐬�����i�˗����ʃ[������f�[�^���o�ł̑Ώۃf�[�^�j
      -- ===========================================================================================
      <<zero_can_loop>>
      FOR i IN 1..gt_zero_can_data.COUNT LOOP
--
        prc_create_can_data
          (
            iv_request_no           => gt_zero_can_data(i).request_no -- �˗�No
            ,iv_eos_shipped_locat   => NULL                      -- �g�p���Ȃ�����NULL
            ,iv_eos_freight_carrier => NULL                      -- �g�p���Ȃ�����NULL
            ,ov_errbuf              => lv_errbuf
            ,ov_retcode             => lv_retcode
            ,ov_errmsg              => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := gn_error_cnt + 1 ;
          RAISE global_process_expt;
        END IF ;
--
      END LOOP zero_can_loop ;
--
    END IF ;
--
-- ##### 20081028 Ver.1.26 ����#143�Ή� END   #####
--
    -- ���o�f�[�^�����݂��Ă��A�ʒm�f�[�^�����݂��Ȃ��ꍇ�A���[�j���O�ŏI���Ƃ���
    IF ( gn_cre_idx = 0 ) THEN
      -- �f�[�^�Ȃ����b�Z�[�W
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_appl_sname_wsh
                      ,iv_name          => lc_msg_code
                    ) ;
      lv_errbuf  := lv_errmsg;
--
      RAISE ex_worn ;
    END IF;
-- ##### 20081007 Ver.1.22 TE080_600�w�E#27�Ή� END   #####
--
    -- =============================================================================================
    -- E-07 �ꊇ�o�^����
    -- =============================================================================================
    prc_ins_temp_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    -- =============================================================================================
    -- E-09 �b�r�u�o�͏���
    -- =============================================================================================
    prc_out_csv_data
      (
        ov_errbuf               => lv_errbuf
       ,ov_retcode              => lv_retcode
       ,ov_errmsg               => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
--
    IF ( gr_param.fix_class = gc_fix_class_k ) THEN    -- �\��m��敪�F�m��
      -- ===========================================================================================
      -- E-12 �ύX�O���폜����
      -- ===========================================================================================
      prc_ins_out_data
        (
          ov_errbuf               => lv_errbuf
         ,ov_retcode              => lv_retcode
         ,ov_errmsg               => lv_errmsg
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
        RAISE global_process_expt;
      END IF ;
--
    END IF ;
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
    -- =============================================================================================
    -- �e���|�����e�[�u���f�[�^�폜
    -- =============================================================================================
    prc_del_tmptable_data
      (
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := gn_error_cnt + 1 ;
      RAISE global_process_expt;
    END IF ;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
  EXCEPTION
    -- =============================================================================================
    -- �x������
    -- =============================================================================================
    WHEN ex_worn THEN
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
      -- ===========================================================================================
      -- �e���|�����e�[�u���f�[�^�폜
      -- ===========================================================================================
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ��tmp2�ɂ̓f�[�^�����݂���ꍇ���݂�̂�
      --     �����ɂč폜���������{
      prc_del_tmptable_data
        (
          ov_errbuf   => lv_errbuf2
         ,ov_retcode  => lv_retcode
         ,ov_errmsg   => lv_errmsg2
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := gn_error_cnt + 1 ;
--
        -- �폜�����G���[�̃��b�Z�[�W�ݒ�
        ov_errmsg  := lv_errmsg2;
        ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf2,1,5000);
        ov_retcode := gv_status_error;
      ELSE
--
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := lv_errbuf ;
        ov_retcode := gv_status_warn;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� START #####
--
      END IF;
-- ##### 20081014 Ver.1.23 PT2-2_17�w�E71�Ή� END   #####
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
  PROCEDURE main
    (
      errbuf              OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W  --# �Œ� #
     ,retcode             OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h    --# �Œ� #
     ,iv_dept_code_01     IN  VARCHAR2          -- 01 : ����_01
     ,iv_dept_code_02     IN  VARCHAR2          -- 02 : ����_02(2008/07/16 Add)
     ,iv_dept_code_03     IN  VARCHAR2          -- 03 : ����_03(2008/07/16 Add)
     ,iv_dept_code_04     IN  VARCHAR2          -- 04 : ����_04(2008/07/16 Add)
     ,iv_dept_code_05     IN  VARCHAR2          -- 05 : ����_05(2008/07/16 Add)
     ,iv_dept_code_06     IN  VARCHAR2          -- 06 : ����_06(2008/07/16 Add)
     ,iv_dept_code_07     IN  VARCHAR2          -- 07 : ����_07(2008/07/16 Add)
     ,iv_dept_code_08     IN  VARCHAR2          -- 08 : ����_08(2008/07/16 Add)
     ,iv_dept_code_09     IN  VARCHAR2          -- 09 : ����_09(2008/07/16 Add)
     ,iv_dept_code_10     IN  VARCHAR2          -- 10 : ����_10(2008/07/16 Add)
     ,iv_fix_class        IN  VARCHAR2          -- 11 : �\��m��敪
     ,iv_date_cutoff      IN  VARCHAR2          -- 12 : ���ߎ��{��
     ,iv_cutoff_from      IN  VARCHAR2          -- 13 : ���ߎ��{����From
     ,iv_cutoff_to        IN  VARCHAR2          -- 14 : ���ߎ��{����To
     ,iv_date_fix         IN  VARCHAR2          -- 15 : �m��ʒm���{��
     ,iv_fix_from         IN  VARCHAR2          -- 16 : �m��ʒm���{����From
     ,iv_fix_to           IN  VARCHAR2          -- 17 : �m��ʒm���{����To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
     ,iv_ship_date_from   IN  VARCHAR2          -- 18 : �o�ɓ�From
     ,iv_ship_date_to     IN  VARCHAR2          -- 19 : �o�ɓ�To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
  )
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
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain
      (
        iv_dept_code_01     => iv_dept_code_01 -- 01 : ����_01
       ,iv_dept_code_02     => iv_dept_code_02 -- 02 : ����_02(2008/07/16 Add)
       ,iv_dept_code_03     => iv_dept_code_03 -- 03 : ����_03(2008/07/16 Add)
       ,iv_dept_code_04     => iv_dept_code_04 -- 04 : ����_04(2008/07/16 Add)
       ,iv_dept_code_05     => iv_dept_code_05 -- 05 : ����_05(2008/07/16 Add)
       ,iv_dept_code_06     => iv_dept_code_06 -- 06 : ����_06(2008/07/16 Add)
       ,iv_dept_code_07     => iv_dept_code_07 -- 07 : ����_07(2008/07/16 Add)
       ,iv_dept_code_08     => iv_dept_code_08 -- 08 : ����_08(2008/07/16 Add)
       ,iv_dept_code_09     => iv_dept_code_09 -- 09 : ����_09(2008/07/16 Add)
       ,iv_dept_code_10     => iv_dept_code_10 -- 10 : ����_10(2008/07/16 Add)
       ,iv_fix_class        => iv_fix_class    -- 11 : �\��m��敪
       ,iv_date_cutoff      => iv_date_cutoff  -- 12 : ���ߎ��{��
       ,iv_cutoff_from      => iv_cutoff_from  -- 13 : ���ߎ��{����From
       ,iv_cutoff_to        => iv_cutoff_to    -- 14 : ���ߎ��{����To
       ,iv_date_fix         => iv_date_fix     -- 15 : �m��ʒm���{��
       ,iv_fix_from         => iv_fix_from     -- 16 : �m��ʒm���{����From
       ,iv_fix_to           => iv_fix_to       -- 17 : �m��ʒm���{����To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
       ,iv_ship_date_from   => iv_ship_date_from  -- 18 : �o�ɓ�From
       ,iv_ship_date_to     => iv_ship_date_to    -- 19 : �o�ɓ�To
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
       ,ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W
       ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h
       ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
      ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    -- �G���[������
    IF ( lv_retcode = gv_status_error ) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
--
    -- �x��������
    IF (   ( lv_retcode = gv_status_warn ) 
       AND ( lv_errmsg IS NOT NULL       ) ) THEN
      FND_FILE.PUT_LINE( FND_FILE.LOG   , lv_errbuf ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_errmsg ) ;
    END IF;
--
    -- ====================================================
    -- �R���J�����g���O�̏o��
    -- ====================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
    -------------------------------------------------------
    -- ���̓p�����[�^
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '���̓p�����[�^' );
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_01 �@�@�@�@�@�@�F' || iv_dept_code_01   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_02 �@�@�@�@�@�@�F' || iv_dept_code_02   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_03 �@�@�@�@�@�@�F' || iv_dept_code_03   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_04 �@�@�@�@�@�@�F' || iv_dept_code_04   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_05 �@�@�@�@�@�@�F' || iv_dept_code_05   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_06 �@�@�@�@�@�@�F' || iv_dept_code_06   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_07 �@�@�@�@�@�@�F' || iv_dept_code_07   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_08 �@�@�@�@�@�@�F' || iv_dept_code_08   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_09 �@�@�@�@�@�@�F' || iv_dept_code_09   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@����_10 �@�@�@�@�@�@�F' || iv_dept_code_10   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�\��m��敪�@�@�@�@�F' || iv_fix_class   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@���ߎ��{���@�@�@�@�@�F' || iv_date_cutoff ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@���ߎ��{����From�@�@�F' || iv_cutoff_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@���ߎ��{����To�@�@�@�F' || iv_cutoff_to   ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�m��ʒm���{���@�@�@�F' || iv_date_fix    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�m��ʒm���{����From�F' || iv_fix_from    ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�m��ʒm���{����To�@�F' || iv_fix_to      ) ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� START #####
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�o�ɓ�From�@�@�@�@�@�F' || iv_ship_date_from ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�o�ɓ�To�@�@�@�@�@�@�F' || iv_ship_date_to   ) ;
-- ##### 20080925 Ver.1.19 TE080_600�w�E#31�Ή� END   #####
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
-- ##### 20081023 Ver.1.25 T_S_440�Ή� START #####
    -- �ʒm��̃��b�Z�[�W�o��
    IF ( gn_notif_idx <> 0 ) THEN
--
      -- �^�C�g���\��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- ��s
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�d�n�r����@�ʒm���[�U�[') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '------------------------') ;
--
      FOR i IN 1..gn_notif_idx LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gt_notif_msg(i) ) ;
      END LOOP ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '' ) ;          -- ��s
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;  -- ��؂蕶����o��
--
    END IF;
-- ##### 20081023 Ver.1.25 T_S_440�Ή� END   #####
--
    -------------------------------------------------------
    -- �x�����b�Z�[�W
    -------------------------------------------------------
    IF ( gn_wrm_idx <> 0 ) THEN
      FOR i IN 1..gn_wrm_idx LOOP
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gt_worm_msg(i) ) ;
      END LOOP ;
--
      lv_retcode := gv_status_warn ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_sep_msg ) ;   --��؂蕶����o��
--
    END IF ;
--
    -------------------------------------------------------
    -- ��������
    -------------------------------------------------------
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�b�r�u�o�͌���' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�o�ׁF' || TO_CHAR( gn_out_cnt_syu, 'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�x���F' || TO_CHAR( gn_out_cnt_shi, 'FM999,999,990' ) ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '�@�ړ��F' || TO_CHAR( gn_out_cnt_mov, 'FM999,999,990' ) ) ;
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
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
END xxwsh600002c ;
/
