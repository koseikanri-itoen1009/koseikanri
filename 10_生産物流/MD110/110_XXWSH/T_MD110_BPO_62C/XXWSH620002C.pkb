CREATE OR REPLACE PACKAGE BODY xxwsh620002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620002c(body)
 * Description      : �o�ɔz���˗��\
 * MD.050           : ����/�z��(���[) T_MD050_BPO_620
 * MD.070           : �o�ɔz���˗��\ T_MD070_BPO_62C
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_initialize         PROCEDURE : ��������(F-1,F-2,F-3)
 *  prc_get_report_data    PROCEDURE : ���[�f�[�^�擾����(F-4)
 *  prc_create_xml_data    PROCEDURE : XML��������(F-5)
 *  fnc_convert_into_xml   FUNCTION  : XML�f�[�^�ϊ�(F-5)
 *  submain                PROCEDURE : ���C�������v���V�[�W��
 *  main                   PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/30    1.0   Yoshitomo Kawasaki �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada       �o�͒S�������̒l���R�[�h���疼�̂ɏC���BGLOBAL�ϐ�������
 *                                       �^���˗����̖��̂� ����=>��Ж� ���� ��Ж� => �����ɏC��
 *  2008/06/12    1.2   Kazuo Kumamoto   �p�����[�^.�Ɩ���ʂɂ���Ē��o�Ώۂ�I��
 *  2008/06/18    1.3   Kazuo Kumamoto   �����e�X�g��Q�Ή�
 *                                       (�z��No���ݒ�̏ꍇ�͐��ʍ��v�A���ݏd�ʁA���ڑ̐ς��o�͂��Ȃ�)
 *  2008/06/23    1.4   Yoshikatsu Shindou �z���敪���VIEW�̃����[�V�������O�������ɕύX
 *                                         (�V�X�e���e�X�g�s�#229)
 *                                         �����敪���擾�ł��Ȃ��ꍇ,�d�ʗe�ύ��v��NULL�Ƃ���B
 *  2008/07/02    1.5   Satoshi Yunba    �֑������Ή�
 *  2008/07/04    1.6   Naoki Fukuda     ST�s��Ή�#394
 *  2008/07/04    1.7   Naoki Fukuda     ST�s��Ή�#409
 *  2008/07/07    1.8   Naoki Fukuda     ST�s��Ή�#337
 *  2008/07/09    1.9   Satoshi Takemoto �ύX�v���Ή�#92,#98
 *  2008/07/17    1.10  Kazuo Kumamoto   �����e�X�g��Q�Ή�
 *                                       1.10.1 �p�����[�^.�i�ڋ敪���w�莞�̕i�ڋ敪�����󗓂Ƃ���B
 *                                       1.10.2 �x���̔z���擙�̏��擾���ύX�B
 *                                       1.10.3 �z���悪���ڂ��Ă���ꍇ�͑S�Ă̔z������o�͂���B
 *  2008/07/17    1.11  Satoshi Takemoto �����e�X�g�s��Ή�(�ύX�v���Ή�#92,#98)
 *  2008/08/04    1.12  Takao Ohashi     �����o�׃e�X�g(�o�גǉ�_18,19,20)�C��
 *  2008/10/27    1.13  Masayoshi Uehara �����w�E297�AT_TE080_BPO_620 �w�E35�w�E45�w�E47
 *                                       T_S_501T_S_601T_S_607�AT_TE110_BPO_230-001 �w�E440
 *                                       �ۑ�#32 �P��/�������Z�̏������W�b�N
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���������ʗ�O ***
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gc_pkg_name                 CONSTANT  VARCHAR2(100) := 'xxwsh620002c' ;   -- �p�b�P�[�W��
  gc_report_id                CONSTANT  VARCHAR2(12)  := 'XXWSH620002T' ;   -- ���[ID
  -- ���[�^�C�g��
  gc_rpt_title_haisou_yotei   CONSTANT  VARCHAR2(10)  := '�z���\��\' ;     -- �z���\��\
  gc_rpt_title_haisou_irai    CONSTANT  VARCHAR2(10)  := '�z���˗��\' ;     -- �z���˗��\
  gc_rpt_title_shukko_yotei   CONSTANT  VARCHAR2(10)  := '�o�ɗ\��\' ;     -- �o�ɗ\��\
  gc_rpt_title_shukko_irai    CONSTANT  VARCHAR2(10)  := '�o�Ɉ˗��\' ;     -- �o�Ɉ˗��\
  -- �\��m��敪
  gc_plan_decide_p            CONSTANT  VARCHAR2(1)   := '1' ;              -- �\��
  gc_plan_decide_d            CONSTANT  VARCHAR2(1)   := '2' ;              -- �m��
  -- �o�ɔz���敪
  gc_shukko_haisou_kbn_p      CONSTANT  VARCHAR2(1)   := '1' ;              -- �o��
  gc_shukko_haisou_kbn_d      CONSTANT  VARCHAR2(1)   := '2' ;              -- �z��
  -- �o�̓^�O
  gc_tag_type_tag             CONSTANT  VARCHAR2(1)   := 'T' ;              -- �O���[�v�^�O
  gc_tag_type_data            CONSTANT  VARCHAR2(1)   := 'D' ;              -- �f�[�^�^�O
  -- ���t�t�H�[�}�b�g
  gc_date_fmt_all             CONSTANT  VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;  -- �N���������b
  gc_date_fmt_ymd             CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD' ;             -- �N����
  gc_date_fmt_hh24mi          CONSTANT  VARCHAR2(10)  := 'HH24:MI' ;                -- ����
  gc_date_fmt_ymd_ja          CONSTANT  VARCHAR2(20)  := 'YYYY"�N"MM"��"DD"��' ;    -- ����
  -- �����^�C�v
  gc_doc_type_code_syukka     CONSTANT  VARCHAR2(2)   := '10' ;             -- �o�׈˗�
  gc_doc_type_code_mv         CONSTANT  VARCHAR2(2)   := '20' ;             -- �ړ�
  gc_doc_type_code_shikyu     CONSTANT  VARCHAR2(2)   := '30' ;             -- �x���w��
  -- ���R�[�h�^�C�v
  gc_rec_type_code_ins        CONSTANT  VARCHAR2(2)   := '10' ;             -- �w��
  -- �V�K�C���t���O
  gc_new_modify_flg_mod       CONSTANT  VARCHAR2(1)   := 'M' ;              -- �C��
  gc_asterisk                 CONSTANT  VARCHAR2(1)   := '*' ;              -- �Œ�l�u*�v
  -- ���i�敪
  gc_prod_cd_leaf             CONSTANT  VARCHAR2(1)   := '1' ;              -- ���[�t   --v1.13�ǉ�
  gc_prod_cd_drink            CONSTANT  VARCHAR2(1)   := '2' ;              -- �h�����N
  gc_item_cd_prdct            CONSTANT  VARCHAR2(1)   := '5' ;              -- ���i
  gc_item_cd_material         CONSTANT  VARCHAR2(1)   := '1' ;              -- ����
  gc_item_cd_prdct_half       CONSTANT  VARCHAR2(1)   := '4' ;              -- �����i
  -- �����敪
  gc_small_amount_enabled     CONSTANT VARCHAR2(1)    := '1' ;              -- �����敪���Ώ�
  -- ���[�U�[�敪
  gc_user_kbn_inside          CONSTANT  VARCHAR2(1)   := '1' ;              -- ����
  gc_user_kbn_outside         CONSTANT  VARCHAR2(1)   := '2' ;              -- �O��
  -- �d�ʗe�ϋ敪
  gc_wei_cap_kbn_w            CONSTANT  VARCHAR2(1)   := '1' ;              -- �d��
  gc_wei_cap_kbn_c            CONSTANT  VARCHAR2(1)   := '2' ;              -- �e��
  -- �o�׈˗��X�e�[�^�X
  gc_ship_status_close        CONSTANT  VARCHAR2(2)   := '03' ;             -- ���ߍς�
  gc_req_status_juryozumi     CONSTANT  VARCHAR2(2)   := '07' ;             -- ��̍�
  gc_ship_status_delete       CONSTANT  VARCHAR2(2)   := '99' ;             -- ���
  -- �o�׎x���敪
  gc_ship_pro_kbn_shu         CONSTANT  VARCHAR2(1)   := '1' ;              -- �o�׈˗�
  gc_ship_pro_kbn_sik         CONSTANT  VARCHAR2(1)   := '2' ;              -- �x���˗�
  -- �󒍃J�e�S��
  gc_order_cate_ret           CONSTANT  VARCHAR2(10)  := 'RETURN' ;         -- �ԕi�i�󒍂̂݁j
  -- �ʒm�X�e�[�^�X
  gc_fixa_notif_yet           CONSTANT  VARCHAR2(2)   := '10' ;             -- ���ʒm
  gc_fixa_notif_re            CONSTANT  VARCHAR2(2)   := '20' ;             -- �Ēʒm�v
  gc_fixa_notif_end           CONSTANT  VARCHAR2(2)   := '40' ;             -- �m��ʒm��
  -- �ړ��X�e�[�^�X
  gc_move_status_ordered      CONSTANT  VARCHAR2(2)   := '02' ;             -- �˗���
  gc_move_status_not          CONSTANT  VARCHAR2(2)   := '99' ;             -- ���
  -- �ړ��^�C�v
  gc_mov_type_not_ship        CONSTANT  VARCHAR2(5)   := '2' ;              -- �ϑ��Ȃ�
  -- �Ɩ����
  gc_biz_type_cd_ship         CONSTANT  VARCHAR2(1)   := '1' ;              -- �o��
  gc_biz_type_cd_shikyu       CONSTANT  VARCHAR2(1)   := '2' ;              -- �x��
  gc_biz_type_cd_move         CONSTANT  VARCHAR2(1)   := '3' ;              -- �ړ�
-- 2008/07/09 add S.Takemoto start
  gc_biz_type_cd_etc          CONSTANT  VARCHAR2(1)   := '4' ;              -- ���̑�
-- 2008/07/09 add S.Takemoto end
  gc_biz_type_nm_ship         CONSTANT  VARCHAR2(4)   := '�o��' ;           -- �o��
  gc_biz_type_nm_shik         CONSTANT  VARCHAR2(4)   := '�x��' ;           -- �x��
  gc_biz_type_nm_move         CONSTANT  VARCHAR2(4)   := '�ړ�' ;           -- �ړ�
-- 2008/07/09 add S.Takemoto start
  gc_biz_type_nm_etc          CONSTANT  VARCHAR2(6)   := '���̑�' ;              -- ���̑�
-- 2008/07/09 add S.Takemoto end
  -- �ŐV�t���O
  gc_latest_external_flag     CONSTANT  VARCHAR2(1)   := 'Y' ;
  -- �폜�E����t���O
  gc_delete_flg               CONSTANT  VARCHAR2(1)   := 'Y' ;
  -- �^���˗����󎚋敪
  gc_trans_req_prt_enable     CONSTANT  VARCHAR2(1)   := '1' ;              -- �󎚂���
--
  -- ���ߎ��{����
  gc_shime_time_from_def      CONSTANT  VARCHAR2(5)   := '00:00' ;
  gc_shime_time_to_def        CONSTANT  VARCHAR2(5)   := '23:59' ;
-- 2008/07/09 add S.Takemoto start
  gc_non_slip_class_2         CONSTANT  VARCHAR2(1)   := '2' ;              -- 2:�`�[�Ȃ��z��
  gc_deliver_to_class_1       CONSTANT  VARCHAR2(1)   := '1' ;              -- 1:���_
  gc_deliver_to_class_4       CONSTANT  VARCHAR2(1)   := '4' ;              -- 4:�ړ�
  gc_deliver_to_class_10      CONSTANT  VARCHAR2(2)   := '10' ;             -- 10:�ڋq
  gc_deliver_to_class_11      CONSTANT  VARCHAR2(2)   := '11' ;             -- 11:�x����
  gc_freight_charge_code_1    CONSTANT  VARCHAR2(1)   := '1' ;              -- 1:�Ώ�
  gc_output_code_1            CONSTANT  VARCHAR2(1)   := '1' ;              -- 1:�Ώ�
-- 2008/07/09 add S.Takemoto end
  ------------------------------
  -- �v���t�@�C���֘A
  ------------------------------
  -- ���Ə��R�[�h�i�ɓ����Y�Ɓj
  gc_prof_loc_cd_sg           CONSTANT VARCHAR2(22)   := 'XXWSH_LOCATION_CODE_SG' ;
  -- ��Ж��i�ɓ����j
  gc_prof_company_nm          CONSTANT VARCHAR2(18)   := 'XXWSH_COMPANY_NAME' ;
  -- �o�׏d�ʒP��
  gc_prof_weight_uom          CONSTANT VARCHAR2(16)   := 'XXWSH_WEIGHT_UOM' ;
  -- �o�חe�ϒP��
  gc_prof_capacity_uom        CONSTANT VARCHAR2(18)   := 'XXWSH_CAPACITY_UOM' ;
  -- ���i�敪
  gc_prof_name_item_div       CONSTANT VARCHAR2(30)   := 'XXCMN_ITEM_DIV_SECURITY' ;
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  --�A�v���P�[�V������
  gc_application_wsh          CONSTANT  VARCHAR2(5)    := 'XXWSH' ;         -- ��޵�:�o�ץ������z��
  gc_application_cmn          CONSTANT  VARCHAR2(5)    := 'XXCMN' ;         -- ��޵�:
  --���b�Z�[�WID
  gc_msg_id_required          CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-12102' ;  -- ���Ұ������ʹװ
  gc_msg_id_not_get_prof      CONSTANT  VARCHAR2(15)  := 'APP-XXWSH-12301' ;  -- ���̧�َ擾�װ
  gc_msg_id_no_data           CONSTANT  VARCHAR2(15)  := 'APP-XXCMN-10122' ;  -- ���[0���G���[
  gc_msg_id_shime_time        COnSTANT  VARCHAR2(15)  := 'APP-XXWSH-12256' ;  -- ���ߓ��t������
  --���b�Z�[�W-�g�[�N����
  gc_msg_tkn_nm_parmeta       CONSTANT  VARCHAR2(10)  := 'PARMETA' ;          -- �p�����[�^��
  gc_msg_tkn_nm_prof          CONSTANT  VARCHAR2(10)  := 'PROF_NAME' ;        -- �v���t�@�C����
  --���b�Z�[�W-�g�[�N���l
  gc_msg_tkn_val_parmeta1     CONSTANT  VARCHAR2(20)  := '�^���Ǝ�' ;
  gc_msg_tkn_val_parmeta2     CONSTANT  VARCHAR2(20)  := '�m��ʒm���{��' ;
  gc_msg_tkn_val_prof_prod1   CONSTANT  VARCHAR2(30)  := 'XXWSH:���Ə��R�[�h(�ɓ����Y��)' ;
  gc_msg_tkn_val_prof_prod2   CONSTANT  VARCHAR2(30)  := '��Ж�(�ɓ���)' ;
  gc_msg_tkn_val_prof_prod3   CONSTANT  VARCHAR2(30)  := 'XXWSH:�o�׏d�ʒP��' ;
  gc_msg_tkn_val_prof_prod4   CONSTANT  VARCHAR2(30)  := 'XXWSH:�o�חe�ϒP��' ;
  gc_msg_tkn_val_prof_prod5   CONSTANT  VARCHAR2(30)  := 'XXCMN�F���i�敪(�Z�L�����e�B)' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  ------------------------------
  -- �o�̓f�[�^�֘A
  ------------------------------
  -- ���R�[�h�錾�p
  xcs         xxwsh_carriers_schedule%ROWTYPE ;         -- �z�Ԕz���v��(�A�h�I��)
  xoha        xxwsh_order_headers_all%ROWTYPE ;         -- �󒍃w�b�_�A�h�I��
  xott2v      xxwsh_oe_transaction_types2_v%ROWTYPE ;   -- �󒍃^�C�v���VIEW2
  xola        xxwsh_order_lines_all%ROWTYPE ;           -- �󒍖��׃A�h�I��
  xmld        xxinv_mov_lot_details%ROWTYPE ;           -- �ړ����b�g�ڍ�(�A�h�I��)
  ilm         ic_lots_mst%ROWTYPE ;                     -- OPM���b�g�}�X�^
  xil2v       xxcmn_item_locations2_v%ROWTYPE ;         -- OPM�ۊǏꏊ���VIEW2
  xcas2v      xxcmn_cust_acct_sites2_v%ROWTYPE ;        -- �ڋq�T�C�g���VIEW2
  xc2v        xxcmn_carriers2_v%ROWTYPE ;               -- �^���Ǝҏ��VIEW2
  xim2v       xxcmn_item_mst2_v%ROWTYPE ;               -- OPM�i�ڏ��VIEW2
  xic4v       xxcmn_item_categories4_v%ROWTYPE ;        -- OPM�i�ڃJ�e�S���������VIEW4
  xtc         xxwsh_tightening_control%ROWTYPE ;        -- �o�׈˗����ߊǗ�(�A�h�I��)
  xl2v        xxcmn_locations2_v%ROWTYPE ;              -- ���Ə����VIEW2
  fu          fnd_user%ROWTYPE ;                        -- ���[�U�[�}�X�^
  xsm2v       xxwsh_ship_method2_v%ROWTYPE ;            -- �z���敪���VIEW2
--
  xca2v       xxcmn_cust_accounts2_v%ROWTYPE ;          -- �ڋq���VIEW2
  xmrih       xxinv_mov_req_instr_headers%ROWTYPE ;     -- �ړ��˗� �w���w�b�_(�A�h�I��)
--
  ------------------------------
  -- ���̓p�����[�^�֘A
  ------------------------------
  -- ���̓p�����[�^�i�[�p���R�[�h
  TYPE rec_param_data IS RECORD(
     iv_dept                    VARCHAR2(10)                    --  01 : ����
    ,iv_plan_decide_kbn         VARCHAR2(1)                     --  02 : �\��/�m��敪
    ,iv_ship_from               DATE                            --  03 : �o�ɓ�From
    ,iv_ship_to                 DATE                            --  04 : �o�ɓ�To
    ,iv_shukko_haisou_kbn       VARCHAR2(1)                     --  05 : �o��/�z���敪
    ,iv_gyoumu_shubetsu         VARCHAR2(1)                     --  06 : �Ɩ����
    ,iv_notif_date              DATE                            --  07 : �m��ʒm���{��
    ,iv_notif_time_from         VARCHAR2(5)                     --  08 : �m��ʒm���{����From
    ,iv_notif_time_to           VARCHAR2(5)                     --  09 : �m��ʒm���{����To
    --,iv_freight_carrier_code    xoha.career_id%TYPE             --  10 : �^���Ǝ�    --2008/07/04 ST�s��Ή�#409
    ,iv_freight_carrier_code    xoha.freight_carrier_code%TYPE  --  10 : �^���Ǝ�      --2008/07/04 ST�s��Ή�#409
    ,iv_block1                  VARCHAR2(5)                     --  11 : �u���b�N1
    ,iv_block2                  VARCHAR2(5)                     --  12 : �u���b�N2
    ,iv_block3                  VARCHAR2(5)                     --  13 : �u���b�N3
    ,iv_shipped_locat_code      VARCHAR2(4)                     --  14 : �o�Ɍ�
    ,iv_mov_num                 VARCHAR2(12)                    --  15 : �˗�No/�ړ�No
    ,iv_shime_date              DATE                            --  16 : ���ߎ��{��
    ,iv_shime_time_from         VARCHAR2(5)                     --  17 : ���ߎ��{����From
    ,iv_shime_time_to           VARCHAR2(5)                     --  18 : ���ߎ��{����To
    ,iv_online_kbn              VARCHAR2(1)                     --  19 : �I�����C���Ώۋ敪
    ,iv_item_kbn                VARCHAR2(1)                     --  20 : �i�ڋ敪
    ,iv_shukko_keitai           VARCHAR2(240)                   --  21 : �o�Ɍ`��
    ,iv_unsou_irai_inzi_kbn     VARCHAR2(1)                     --  22 : �^���˗����󎚋敪
  );
  type_rec_param_data   rec_param_data ;
--
  -- �o�̓f�[�^�i�[�p���R�[�h
  TYPE rec_report_data IS RECORD
  (
-- 2008/07/09 mod S.Takemoto start
--     gyoumu_shubetsu            VARCHAR2(4)                           -- �Ɩ����
     gyoumu_shubetsu            VARCHAR2(6)                           -- �Ɩ����
-- 2008/07/09 mod S.Takemoto end
    ,gyoumu_shubetsu_code       VARCHAR2(1)                           -- �Ɩ���ʃR�[�h
    ,freight_carrier_code       xoha.freight_carrier_code%TYPE        -- �^���Ǝ�
    ,carrier_full_name          xc2v.party_name%TYPE                  -- �^���Ǝ�(����)
    ,deliver_from               xoha.deliver_from%TYPE                -- �o�Ɍ�
    ,description                xil2v.description%TYPE                -- �o�Ɍ�(����)
    ,schedule_ship_date         xoha.schedule_ship_date%TYPE          -- �o�ɓ�
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    ,item_class_code            xic4v.item_class_code%TYPE            -- �i�ڋ敪
-- 2008/10/27 mod end 1.13 
    ,item_class_name            xic4v.item_class_name%TYPE            -- �i�ڋ敪��
    ,new_modify_flg             xoha.new_modify_flg%TYPE              -- �V�K�C���t���O
    ,schedule_arrival_date      xoha.schedule_arrival_date%TYPE       -- ����
    ,delivery_no                xoha.delivery_no%TYPE                 -- �z��No
    ,shipping_method_code       xoha.shipping_method_code%TYPE        -- �z���敪
    ,ship_method_meaning        xsm2v.ship_method_meaning%TYPE        -- �z���敪����
    ,head_sales_branch          xoha.head_sales_branch%TYPE           -- �Ǌ����_
    ,party_name                 xca2v.party_name%TYPE                 -- �Ǌ����_(����)
    ,deliver_to                 xoha.deliver_to%TYPE                  -- �z����
    ,party_site_full_name       xcas2v.party_site_full_name%TYPE      -- �z����(������)
    ,address_line1              xxcmn_locations2_v.address_line1%TYPE -- �z����(�Z��1)
    ,address_line2              xcas2v.address_line2%TYPE             -- �z����(�Z��2)
    ,phone                      xcas2v.phone%TYPE                     -- �z����(�d�b�ԍ�)
    ,arrival_time_from          xoha.arrival_time_from%TYPE           -- ���Ԏw��From
    ,arrival_time_to            xoha.arrival_time_to%TYPE             -- ���Ԏw��To
    ,sum_loading_capacity       xcs.sum_loading_capacity%TYPE         -- ���ڑ̐�
    ,sum_loading_weight         xcs.sum_loading_weight%TYPE           -- ���ڏd��
    ,req_mov_no                 xoha.request_no%TYPE                  -- �˗�No/�ړ�No
    ,sum_weightm_capacity       NUMBER                                -- �d�ʑ̐�(�˗�No.�P��)
    ,sum_weightm_capacity_t     VARCHAR2(240)                         -- �P��
    ,tehai_no                   xmrih.batch_no%TYPE                   -- ��zNo
    ,prev_delivery_no           xoha.prev_delivery_no%TYPE            -- �O��z��No
    ,po_no                      xoha.po_no%TYPE                       -- PoNo
    ,jpr_user_code              xcas2v.jpr_user_code%TYPE             -- JPR���[�U�R�[�h
    ,collected_pallet_qty       xoha.collected_pallet_qty%TYPE        -- �p���b�g�������
    ,shipping_instructions      xoha.shipping_instructions%TYPE       -- �E�v
    ,slip_number                xoha.slip_number%TYPE                 -- �����No
    ,small_quantity             xoha.small_quantity%TYPE              -- ��
    ,item_code                  xola.shipping_item_code%TYPE          -- �i��(�R�[�h)
    ,item_name                  xim2v.item_short_name%TYPE            -- �i��(����)
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    ,lot_id                     xmld.lot_id%TYPE                      -- ���b�gID
-- 2008/10/27 mod end 1.13 
    ,lot_no                     xmld.lot_no%TYPE                      -- ���b�gNo
    ,attribute1                 ilm.attribute1%TYPE                   -- ������
    ,attribute3                 ilm.attribute3%TYPE                   -- �ܖ�����
    ,attribute2                 ilm.attribute2%TYPE                   -- �ŗL�L��
    ,num_of_cases               xim2v.num_of_cases%TYPE               -- ����
    ,net                        xim2v.net%TYPE                        -- �d��(NET)
    ,qty                        xmld.actual_quantity%TYPE             -- ����
    ,conv_unit                  xim2v.conv_unit%TYPE                  -- ���o�Ɋ��Z�P��
    
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_loc_cd_sg          VARCHAR2(20);                               -- �ɓ����Y�Ǝ��Ə��R�[�h
  gv_company_nm         VARCHAR2(20);                               -- ��Ж�
  gv_uom_weight         VARCHAR2(3);                                -- �o�׏d�ʒP��
  gv_uom_capacity       VARCHAR2(3);                                -- �o�חe�ϒP��
--
  gt_report_data        list_report_data ;                          -- �o�̓f�[�^
  gv_report_title       VARCHAR2(20) ;                              -- ���[�^�C�g��
  gt_xml_data_table     XML_DATA ;                                  -- XML�f�[�^
  gt_param              rec_param_data ;                            -- ���̓p�����[�^���
  gv_dept_cd            VARCHAR2(10) ;                              -- �S������
  -- MOD START 2008/06/04 NAKADA gv_user_nm��V�K�ɒǉ��Bgv_dept_nm��S���������p�Ƃ��A�����ύX
  gv_dept_nm            VARCHAR2(20) ;                              -- �S��������
  gv_user_nm            VARCHAR2(14) ;                              -- �S����
  -- MOD END   2008/06/04 NAKADA
  -- �^��������
  gv_hchu_postal_code        xxcmn_locations_all.zip%TYPE ;           -- �X�֔ԍ�
  gv_hchu_address_value      xxcmn_locations_all.address_line1%TYPE ; -- �Z��
  gv_hchu_tel_value          xxcmn_locations_all.phone%TYPE ;         -- �d�b�ԍ�
  gv_hchu_fax_value          xxcmn_locations_all.fax%TYPE ;           -- FAX�ԍ�
  gv_hchu_cat_value          xxcmn_locations_all.location_name%TYPE ; -- ��������
  -- �^���˗���
  gv_irai_postal_code        xxcmn_locations_all.zip%TYPE ;           -- �X�֔ԍ�
  gv_irai_address_value      xxcmn_locations_all.address_line1%TYPE ; -- �Z��
  gv_irai_tel_value          xxcmn_locations_all.phone%TYPE ;         -- �d�b�ԍ�
  gv_irai_fax_value          xxcmn_locations_all.fax%TYPE ;           -- FAX�ԍ�
  gv_irai_cat_value          xxcmn_locations_all.location_name%TYPE ; -- ��������
  gv_irai_cat_value_full     VARCHAR2(74);                            -- �������́{��Ж�
--
  gv_prod_kbn           VARCHAR2(1);                                  -- ���i�敪
--
  gd_common_sysdate     DATE;                                         -- �V�X�e�����t
--
  gv_papf_attribute3  per_all_people_f.attribute3%TYPE ; -- ���[�U�[�������q��:"1" �O���q��:"2" 2008/07/04 ST�s��Ή�#394
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : ��������(F-1,F-2,F-3)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- �v���O������
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
    -- *** ���[�J���E��O���� ***
    prm_check_expt     EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
    get_prof_expt      EXCEPTION ;     -- �v���t�@�C���擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    gd_common_sysdate :=  SYSDATE ;   -- �V�X�e�����t
--
    -- ====================================================
    -- �v���t�@�C���l�擾(F-1)
    -- ====================================================
    -- �uXXWSH:���Ə��R�[�h�i�ɓ����Y�Ɓj�v
    gv_loc_cd_sg := FND_PROFILE.VALUE(gc_prof_loc_cd_sg) ;
    IF (gv_loc_cd_sg IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod1
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- �uXXWSH:��Ж��i�ɓ����j�v
    gv_company_nm := FND_PROFILE.VALUE(gc_prof_company_nm) ;
    IF (gv_company_nm IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod2
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- �uXXWSH:�o�׏d�ʒP�ʁv
    gv_uom_weight := FND_PROFILE.VALUE(gc_prof_weight_uom) ;
    IF (gv_uom_weight IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod3
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- �uXXWSH:�o�חe�ϒP�ʁv
    gv_uom_capacity := FND_PROFILE.VALUE(gc_prof_capacity_uom) ;
    IF (gv_uom_capacity IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod4
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- �E�ӁF���i�敪(�Z�L�����e�B)�擾
    gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod5
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
    -- ====================================================
    -- �p�����[�^�`�F�b�N(F-2)
    -- ====================================================
    -- 2008/07/07 ST�s��Ή�#337 �z���̏ꍇ�ł��p�����[�^�^���Ǝ҂�K�{�Ƃ��Ȃ�
    ---- �p�����[�^�o��/�z���敪�̒l���A�z���̏ꍇ�Ƀp�����[�^�^���Ǝ҂�K�{�Ƃ��܂��B
    --IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
    --  IF ( gt_param.iv_freight_carrier_code IS NULL ) THEN
    --    -- ���b�Z�[�W�Z�b�g
    --    lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
    --                                          ,gc_msg_id_required
    --                                          ,gc_msg_tkn_nm_parmeta
    --                                          ,gc_msg_tkn_val_parmeta1
    --                                         ) ;
    --    RAISE prm_check_expt ;
    --  END IF ;
    --END IF ;
    --
--
    -- �p�����[�^�\��/�m��敪���m��̏ꍇ�A�m��ʒm���{����K�{�Ƃ��܂��B
    --2008/07/04 ST�s��Ή�#394 �A�����[�U�[�������q�ɂ̏ꍇ�����K�{�`�F�b�N����i�O���q�ɂ̏ꍇ�͍s��Ȃ��j
    SELECT
      NVL(papf.attribute3,gc_user_kbn_inside)  --NULL�̃��[�U�[�͓����q�Ɉ���
    INTO
      gv_papf_attribute3
    FROM fnd_user fu 
        ,per_all_people_f papf
    WHERE fu.user_id     = FND_GLOBAL.USER_ID
      AND fu.employee_id = papf.person_id;
    --2008/07/04 ST�s��Ή�#394
--
-- 2008/10/27 del start1.13 �����w�E297 �m����{���͕K�{����C�ӂɕύX����B
--    IF ( gv_papf_attribute3 = gc_user_kbn_inside ) THEN  --2008/07/04 ST�s��Ή�#394
--      IF ( gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN -- �p�����[�^�\��/�m��敪���m��̏ꍇ
--        IF ( gt_param.iv_notif_date IS NULL ) THEN
--          -- ���b�Z�[�W�Z�b�g
--          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
--                                                ,gc_msg_id_required
--                                                ,gc_msg_tkn_nm_parmeta
--                                                ,gc_msg_tkn_val_parmeta2
--                                               ) ;
--          RAISE prm_check_expt ;
--        END IF ;
--      END IF ;
--    END IF ;
-- 2008/10/27 del end 1.13
    -- �p�����[�^���ߎ��{���������͂̏ꍇ�ɁA���ߎ��{����From��To�ɓ��͂��������ꍇ�A
    -- �G���[�Ƃ���B
    IF ( gt_param.iv_shime_date IS NULL ) THEN
      IF  ( ( gt_param.iv_shime_time_from IS NOT NULL )
        OR  ( gt_param.iv_shime_time_to   IS NOT NULL ) ) THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                              ,gc_msg_id_shime_time
                                             ) ;
        RAISE prm_check_expt ;
      END IF ;
    ELSE
      -- �p�����[�^���ߎ��{�������͂���Ă���A���ߎ��{����From��To�ɓ��͂��Ȃ������ꍇ�A
      -- �f�t�H���g�l���ݒ肳���B
      IF ( gt_param.iv_shime_time_from IS NULL ) THEN
        gt_param.iv_shime_time_from :=  gc_shime_time_from_def ;
      END IF ;
--
      IF ( gt_param.iv_shime_time_to IS NULL ) THEN
        gt_param.iv_shime_time_to :=  gc_shime_time_to_def ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �w�b�_��񒊏o(F-3)
    -- ====================================================
    -- ====================================================
    -- �S���ҏ��擾
    -- ====================================================
    -- �S�������R�[�h
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID), 1, 10) ;
--
    --�S��������
    -- ADD START 2008/06/04 NAKADA
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10) ;
    -- ADD END   2008/06/04 NAKADA
--
    -- �S����
    gv_user_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    IF ( gt_param.iv_unsou_irai_inzi_kbn = gc_trans_req_prt_enable ) THEN
      ----------------------------------------------------------------------
      -- �^��������
      ----------------------------------------------------------------------
      -- �Z���A�d�b�ԍ��A�����������擾
      xxcmn_common_pkg.get_dept_info
      (
         iv_dept_cd           =>  gv_loc_cd_sg          -- �v���t�@�C�����ɓ����Y�Ƃ̎��Ə��R�[�h
        ,id_appl_date         =>  SYSDATE               -- ���
        ,ov_postal_code       =>  gv_hchu_postal_code   -- �X�֔ԍ�
        ,ov_address           =>  gv_hchu_address_value -- �Z��
        ,ov_tel_num           =>  gv_hchu_tel_value     -- �d�b�ԍ�
        ,ov_fax_num           =>  gv_hchu_fax_value     -- FAX�ԍ�
        ,ov_dept_formal_name  =>  gv_hchu_cat_value     -- ����������
        ,ov_errbuf            =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode           =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg            =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
      ----------------------------------------------------------------------
--
      ----------------------------------------------------------------------
      -- �^���˗���
      ----------------------------------------------------------------------
      -- �Z���A�d�b�ԍ��A�����������擾
      xxcmn_common_pkg.get_dept_info
      (
         iv_dept_cd           =>  gv_dept_cd            -- �S������
        ,id_appl_date         =>  SYSDATE               -- ���
        ,ov_postal_code       =>  gv_irai_postal_code   -- �X�֔ԍ�
        ,ov_address           =>  gv_irai_address_value -- �Z��
        ,ov_tel_num           =>  gv_irai_tel_value     -- �d�b�ԍ�
        ,ov_fax_num           =>  gv_irai_fax_value     -- FAX�ԍ�
        ,ov_dept_formal_name  =>  gv_irai_cat_value     -- ����������
        ,ov_errbuf            =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode           =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg            =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
--
      -- �����������ɂ͉�Ж����܂܂�Ă��Ȃ��̂ŁA������A�����s���B
      -- MOD START 2008/06/04 NAKADA ���������̏�������Ж� �������̏��ɏC��
      gv_irai_cat_value_full  :=  SUBSTRB(gv_company_nm || gv_irai_cat_value, 1, 74) ;
      -- MOD END 2008/06/04 NAKADA
--
      ----------------------------------------------------------------------
    ELSE
      gv_hchu_postal_code     :=  NULL ;
      gv_hchu_address_value   :=  NULL ;
      gv_hchu_tel_value       :=  NULL ;
      gv_hchu_fax_value       :=  NULL ;
      gv_hchu_cat_value       :=  NULL ;
--
      gv_irai_postal_code     :=  NULL ;
      gv_irai_address_value   :=  NULL ;
      gv_irai_tel_value       :=  NULL ;
      gv_irai_fax_value       :=  NULL ;
      gv_irai_cat_value       :=  NULL ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
    --*** �v���t�@�C���擾��O�n���h�� ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���[�f�[�^�擾����(F-4)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
     ov_errbuf      OUT   VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode     OUT   VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg      OUT   VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    -- �J�[�\���錾
    -- �J�[�\���^�C�v
    TYPE  cur_typ IS  ref CURSOR;
    -- �J�[�\����`
    c_cur   cur_typ;
    -- ���ISQL�i�[�ϐ�
    lv_sql_head           VARCHAR2(32767);
    lv_sql_shu_sel_from1  VARCHAR2(32767);
    lv_sql_shu_sel_from2  VARCHAR2(32767);
    lv_sql_shu_where1     VARCHAR2(32767);
    lv_sql_shu_where2     VARCHAR2(32767);
    lv_sql_sik_sel_from1  VARCHAR2(32767);
    lv_sql_sik_sel_from2  VARCHAR2(32767);
    lv_sql_sik_where1     VARCHAR2(32767);
    lv_sql_sik_where2     VARCHAR2(32767);
    lv_sql_ido_sel_from1  VARCHAR2(32767);
    lv_sql_ido_sel_from2  VARCHAR2(32767);
    lv_sql_ido_where1     VARCHAR2(32767);
    lv_sql_ido_where2     VARCHAR2(32767);
-- 2008/07/09 add S.Takemoto start
    lv_sql_etc_sel_from1  VARCHAR2(32767);
    lv_sql_etc_sel_from2  VARCHAR2(32767);
    lv_sql_etc_where1     VARCHAR2(32767);
    lv_sql_etc_where2     VARCHAR2(32767);
-- 2008/07/09 add S.Takemoto end
    lv_sql_tail           VARCHAR2(32767);
--add start 1.2
    lb_union              BOOLEAN := FALSE;
--add end 1.2
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- ���[�^�C�g������
    -- ====================================================
    -- �o��/�z���敪���u�z���v�̏ꍇ
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
--
      -- �\��/�m��敪���u�\��v�̏ꍇ
      IF ( gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
        gv_report_title := gc_rpt_title_haisou_yotei;
      -- �\��/�m��敪���u�m��v�̏ꍇ
      ELSE
        gv_report_title := gc_rpt_title_haisou_irai;
      END IF ;
--
    -- �o��/�z���敪���u�o�Ɂv�̏ꍇ
    ELSE
--
      -- �\��/�m��敪���u�\��v�̏ꍇ
      IF ( gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
        gv_report_title := gc_rpt_title_shukko_yotei;
--
      -- �\��/�m��敪���u�m��v�̏ꍇ
      ELSE
        gv_report_title := gc_rpt_title_shukko_irai;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- ���[�f�[�^�擾
    -- ====================================================
    -- ���ISQL
    lv_sql_head := lv_sql_head 
    || ' SELECT ' 
    || ' gyoumu_shubetsu '          -- �Ɩ����
    || ' ,gyoumu_shubetsu_code '    -- �Ɩ���ʃR�[�h
    || ' ,freight_carrier_code '    -- �^���Ǝ�
    || ' ,carrier_full_name '       -- �^���Ǝ�(����)
    || ' ,deliver_from '            -- �o�Ɍ�
    || ' ,description '             -- �o�Ɍ�(����)
    || ' ,schedule_ship_date '      -- �o�ɓ�
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,item_class_code '         -- �i�ڋ敪
-- 2008/10/27 mod end 1.13 
    || ' ,item_class_name '         -- �i�ڋ敪��
    || ' ,new_modify_flg '          -- �V�K�C���t���O
    || ' ,schedule_arrival_date '   -- ����
    || ' ,delivery_no '             -- �z��No
    || ' ,shipping_method_code '    -- �z���敪
    || ' ,ship_method_meaning '     -- �z���敪����
    || ' ,head_sales_branch '       -- �Ǌ����_
    || ' ,party_name '              -- �Ǌ����_(����)
    || ' ,deliver_to '              -- �z����
    || ' ,party_site_full_name '    -- �z����(������)
    || ' ,address_line1 '           -- �z����(�Z��1)
    || ' ,address_line2 '           -- �z����(�Z��2)
    || ' ,phone '                   -- �z����(�d�b�ԍ�)
    || ' ,arrival_time_from '       -- ���Ԏw��From
    || ' ,arrival_time_to '         -- ���Ԏw��To
    || ' ,TRUNC(sum_loading_capacity + 0.9) AS sum_loading_capacity ' -- ���ڑ̐� 2008/07/07 ST�s��Ή�#337
    || ' ,TRUNC(sum_loading_weight + 0.9) AS sum_loading_weight ' --���ڏd�� 2008/07/07 ST�s��Ή�#337
    || ' ,req_mov_no '              -- �˗�No/�ړ�No
    || ' ,TRUNC(sum_weightm_capacity + 0.9) AS sum_weightm_capacity' --�d�ʑ̐�(�˗�No.�P��) 2008/07/07 ST�s��Ή�#337
    || ' ,sum_weightm_capacity_t '  -- �P��
    || ' ,tehai_no '                -- ��zNo
    || ' ,prev_delivery_no '        -- �O��z��No
    || ' ,po_no '                   -- PoNo
    || ' ,jpr_user_code '           -- JPR���[�U�R�[�h
    || ' ,collected_pallet_qty '    -- �p���b�g�������
    || ' ,shipping_instructions '   -- �E�v
    || ' ,slip_number '             -- �����No
    || ' ,small_quantity '          -- ��
    || ' ,item_code '               -- �i��(�R�[�h)
    || ' ,item_name '               -- �i��(����)
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,lot_id '                  -- ���b�gID
-- 2008/10/27 mod end 1.13 
    || ' ,lot_no '                  -- ���b�gNo
    || ' ,attribute1 '              -- ������
    || ' ,attribute3 '              -- �ܖ�����
    || ' ,attribute2 '              -- �ŗL�L��
    || ' ,num_of_cases '            -- ����
    || ' ,net '                     -- �d��(NET)
    || ' ,qty '                     -- ����
    || ' ,conv_unit '               -- ���o�Ɋ��Z�P��
    || ' FROM ' 
    || ' ( ' ;
--
    -- ====================================================
    -- �o�׏��
    -- ====================================================
--add start 1.2
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_ship) = gc_biz_type_cd_ship) THEN
--add end 1.2
    lv_sql_shu_sel_from1  :=  lv_sql_shu_sel_from1
    || ' SELECT ' 
    || ' '''|| gc_biz_type_nm_ship ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_ship ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v.distribution_block AS dist_block ' 
    || ' ,xoha.freight_carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xoha.deliver_from AS deliver_from ' 
    || ' ,xil2v.description AS description ' 
    || ' ,xoha.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,xic4v.item_class_code AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,xic4v.item_class_name AS item_class_name ' 
    || ' ,DECODE(xoha.new_modify_flg, ''' 
      || gc_new_modify_flg_mod ||''', '''
      || gc_asterisk ||''') AS new_modify_flg ' 
    || ' ,xoha.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xoha.delivery_no AS delivery_no ' 
    || ' ,xoha.shipping_method_code AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
    || ' ,xoha.head_sales_branch AS head_sales_branch ' 
    || ' ,xca2v.party_name AS party_name ' 
    || ' ,xoha.deliver_to AS deliver_to ' 
    || ' ,xcas2v.party_site_full_name AS party_site_full_name ' 
    || ' ,xcas2v.address_line1 AS address_line1 ' 
    || ' ,xcas2v.address_line2 AS address_line2 ' 
    || ' ,xcas2v.phone AS phone ' 
    || ' ,xoha.arrival_time_from AS arrival_time_from ' 
    || ' ,xoha.arrival_time_to AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,xoha.request_no AS req_mov_no ' 
    || ' ,CASE' 
    || ' WHEN ( xsm2v.small_amount_class = '''|| gc_small_amount_enabled ||''' ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xoha.sum_weight' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN'    
    || ' xoha.sum_capacity' 
    || ' END' 
    || ' WHEN xsm2v.small_amount_class IS NULL THEN'   -- 6/23 �ǉ�
    || ' NULL'
    || ' ELSE' 
    || ' CASE ' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xola.pallet_weight + xoha.sum_weight' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN' 
    || ' xola.pallet_weight + xoha.sum_capacity' 
    || ' END' 
    || ' END AS sum_weightm_capacity' 
    || ' ,CASE' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' '''|| gv_uom_weight ||''' ' 
    || ' ELSE' 
    || ' '''|| gv_uom_capacity ||''' ' 
    || ' END AS sum_weightm_capacity_t ' 
    || ' ,NULL AS tehai_no ' 
    || ' ,xoha.prev_delivery_no AS prev_delivery_no ' 
    || ' ,xoha.cust_po_number AS po_no ' ;
--
    lv_sql_shu_sel_from2  :=  lv_sql_shu_sel_from2
    || ' ,xcas2v.jpr_user_code AS jpr_user_code ' 
    || ' ,xoha.collected_pallet_qty AS collected_pallet_qty ' 
    || ' ,xoha.shipping_instructions AS shipping_instructions ' 
    || ' ,xoha.slip_number AS slip_number ' 
    || ' ,xoha.small_quantity AS small_quantity ' 
    || ' ,xola.shipping_item_code AS item_code ' 
    || ' ,xim2v.item_short_name AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,xmld.lot_id AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,xmld.lot_no AS lot_no ' 
    || ' ,ilm.attribute1 AS attribute1 ' 
    || ' ,ilm.attribute3 AS attribute3 ' 
    || ' ,ilm.attribute2 AS attribute2 ' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' xim2v.num_of_cases' 
    || ' WHEN ( ilm.attribute6 IS NOT NULL ) THEN' 
    || ' ilm.attribute6' 
    || ' WHEN ( ilm.attribute6 IS NULL ) THEN' 
    || ' xim2v.frequent_qty' 
    || ' END  AS num_of_cases' 
    || ' ,xim2v.net AS net' 
    || ' ,CASE  ' 
    || ' WHEN ( xola.reserved_quantity > 0 ) THEN' 
    || ' CASE ' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' )' 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) ) THEN' 
    || ' xmld.actual_quantity / TO_NUMBER(' 
    || ' CASE' 
    || ' WHEN ( xim2v.num_of_cases > 0 ) THEN' 
    || ' xim2v.num_of_cases' 
    || ' ELSE' 
    || ' TO_CHAR(1)' 
    || ' END)' 
    || ' ELSE' 
    || ' xmld.actual_quantity' 
    || ' END' 
    || ' WHEN ( ( xola.reserved_quantity IS NULL ) ' 
    || ' OR ( xola.reserved_quantity = 0 ) ) THEN' 
    || ' CASE ' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' )' 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) ) THEN' 
    || ' xola.quantity / TO_NUMBER(' 
    || ' CASE' 
    || '  WHEN ( xim2v.num_of_cases > 0 ) THEN' 
    || '  xim2v.num_of_cases' 
    || '  ELSE' 
    || '  TO_CHAR(1)' 
    || ' END' 
    || ' )' 
    || ' ELSE' 
    || ' xola.quantity' 
    || ' END' 
    || ' END  AS qty' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '|| gc_item_cd_prdct ||' )' 
-- 2008/10/27 add start 1.13 �ۑ�32 �P��/�������Z���W�b�N�C��
    || ' AND ( xim2v.num_of_cases > 0 ) ' 
-- 2008/10/27 add end 1.13 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xim2v.conv_unit' 
    || ' ELSE' 
    || ' xim2v.item_um' 
    || ' END  AS conv_unit' 
    || ' FROM' 
    || ' xxwsh_carriers_schedule xcs '            -- �z�Ԕz���v��(�A�h�I��)
    || ' ,xxwsh_order_headers_all xoha '          -- �󒍃w�b�_�A�h�I��
    || ' ,xxwsh_oe_transaction_types2_v xott2v '  -- �󒍃^�C�v���VIEW2
    || ' ,xxwsh_order_lines_all xola '            -- �󒍖��׃A�h�I��
    || ' ,xxinv_mov_lot_details xmld '            -- �ړ����b�g�ڍ�(�A�h�I��)
    || ' ,ic_lots_mst ilm '                       -- OPM���b�g�}�X�^
    || ' ,xxcmn_item_locations2_v xil2v '         -- OPM�ۊǏꏊ���VIEW2
    || ' ,xxcmn_cust_acct_sites2_v xcas2v '       -- �ڋq�T�C�g���VIEW2
    || ' ,xxcmn_cust_accounts2_v xca2v '          -- �ڋq���VIEW2
    || ' ,xxcmn_carriers2_v xc2v '                -- �^���Ǝҏ��VIEW2
    || ' ,xxcmn_item_mst2_v xim2v '               -- OPM�i�ڏ��VIEW2
    || ' ,xxcmn_item_categories4_v xic4v '        -- OPM�i�ڃJ�e�S���������VIEW4
    || ' ,xxwsh_tightening_control xtc '          -- �o�׈˗����ߊǗ�(�A�h�I��)
    || ' ,fnd_user fu '                           -- ���[�U�[�}�X�^
    || ' ,per_all_people_f papf '                 -- �]�ƈ��}�X�^
    || ' ,xxwsh_ship_method2_v xsm2v ' ;          -- �z���敪���VIEW2
--
    lv_sql_shu_where1 :=  lv_sql_shu_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- �󒍃w�b�_�A�h�I��
    -------------------------------------------------------------------------------
    IF ( gt_param.iv_mov_num IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' ( xoha.request_no = '''|| gt_param.iv_mov_num ||''') AND ' ;
    END IF ;
    lv_sql_shu_where1 :=  lv_sql_shu_where1 
    || ' xoha.req_status >= '''|| gc_ship_status_close ||'''' 
    || ' AND xoha.req_status <> '''|| gc_ship_status_delete ||'''' 
    || ' AND xoha.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xoha.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( xoha.freight_carrier_code = '''|| gt_param.iv_freight_carrier_code ||''')' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_date IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( TRUNC(TO_DATE(xoha.notif_date,'''|| gc_date_fmt_all ||'''))' 
      || ' = TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_notif_date) ||''', '''
                              || gc_date_fmt_all ||''')) )' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( TO_CHAR(xoha.notif_date, '''
      || gc_date_fmt_hh24mi ||''') >= '''|| gt_param.iv_notif_time_from ||''')' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where1 :=  lv_sql_shu_where1
      || ' AND ( TO_CHAR(xoha.notif_date, '''
      || gc_date_fmt_hh24mi ||''') <= '''|| gt_param.iv_notif_time_to ||''')' ;
    END IF ;
    IF ( gt_param.iv_dept IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( xoha.instruction_dept = '''|| gt_param.iv_dept ||''')' ;
    END IF ;
    lv_sql_shu_where1 :=  lv_sql_shu_where1 
    || ' AND (' 
    || ' (' 
    || ' ( '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_p ||''' )'
    || ' AND' 
    || ' ( xoha.notif_status IN ('''|| gc_fixa_notif_yet ||''', '''|| gc_fixa_notif_re ||''') )'
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' ( '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_d ||''' )' 
    || ' AND' 
    || ' ( xoha.notif_status = '''|| gc_fixa_notif_end ||''')' 
    || ' )' 
    || ' )' 
    || ' AND xoha.latest_external_flag = ''' || gc_latest_external_flag ||''''
    -------------------------------------------------------------------------------
    -- �z�Ԕz���v��(�A�h�I��)
    -------------------------------------------------------------------------------
    || ' AND xoha.delivery_no = xcs.delivery_no(+)' 
    -------------------------------------------------------------------------------
    -- �z���敪���VIEW2
    -------------------------------------------------------------------------------
    || ' AND xoha.shipping_method_code = xsm2v.ship_method_code(+)'  -- 6/23 �O�������ǉ�
    ------------------------------------------------
    -- �󒍃^�C�v���VIEW2
    ------------------------------------------------
    || ' AND xoha.order_type_id = xott2v.transaction_type_id' ;
    IF ( gt_param.iv_shukko_keitai IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND xott2v.transaction_type_id = '''|| gt_param.iv_shukko_keitai ||'''' ;
    END IF ;
    lv_sql_shu_where1 :=  lv_sql_shu_where1 
    || ' AND xott2v.shipping_shikyu_class = '''|| gc_ship_pro_kbn_shu || ''''
    || ' AND xott2v.order_category_code <> '''|| gc_order_cate_ret ||'''' 
    ------------------------------------------------
    -- OPM�ۊǏꏊ���VIEW2
    ------------------------------------------------
    || ' AND xoha.deliver_from_id = xil2v.inventory_location_id';
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND xil2v.eos_control_type = '''|| gt_param.iv_online_kbn ||'''' ;
    END IF ;
-- 2008/10/27 add start 1.13 T_TE080_BPO_620�w�E47 �o�ɔz���敪���o�ɂ̏ꍇ�A�q�Ɍ��^���Ǝ҂����O
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_shu_where1 :=  lv_sql_shu_where1 
      || ' AND ( xil2v.eos_detination <> xc2v.eos_detination ) ' ;
    END IF ;
-- 2008/10/27 add end 1.13 
    lv_sql_shu_where1 :=  lv_sql_shu_where1
    || ' AND (' 
    || ' xil2v.distribution_block IN ( '''|| gt_param.iv_block1 ||'''' 
    || '  , '''|| gt_param.iv_block2 ||'''' 
    || '  , '''|| gt_param.iv_block3 ||''' )' 
    || ' OR' 
    || ' xoha.deliver_from = '''|| gt_param.iv_shipped_locat_code ||''' '
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    ------------------------------------------------
    -- �ڋq�T�C�g���VIEW2
    ------------------------------------------------
    || ' AND xoha.deliver_to_id = xcas2v.party_site_id' 
    || ' AND xcas2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xcas2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xcas2v.end_date_active IS NULL' 
    || ' )' ;
    -------------------------------------------------------------------------------
    -- �ڋq���VIEW2
    -------------------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- �Ǌ����_
    -- �Ǌ����_�i���́j
--
    lv_sql_shu_where2 :=  lv_sql_shu_where2
    || ' AND xoha.head_sales_branch = xca2v.party_number' 
    || ' AND xca2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xca2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xca2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    ------------------------------------------------
    -- �^���Ǝҏ��VIEW2
    ------------------------------------------------
    ----------------------------------------------------------------------
    -- �^���Ǝ�
    -- �^���Ǝҁi���́j
    || ' AND xoha.career_id = xc2v.party_id(+)' 
    || ' AND (' 
    || ' xc2v.start_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.start_date_active <= xoha.schedule_ship_date' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.end_date_active >= xoha.schedule_ship_date' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||''' '
    || ' AND' 
    || ' xoha.freight_carrier_code <> xoha.deliver_from' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||''' '
    || ' )' 
    ------------------------------------------------
    -- �o�׈˗����ߊǗ�(�A�h�I��)
    ------------------------------------------------
    || ' AND xoha.tightening_program_id = xtc.concurrent_id(+)' ;
-- 2008/10/27 mod start1.13�d�l�s��T_S_601 �\��˗��敪���\��̎��A���ߎ��{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_shime_date IS NOT NULL ) THEN
    IF ( gt_param.iv_shime_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where2 :=  lv_sql_shu_where2
      || ' AND TRUNC(xtc.tightening_date) = ' 
      || ' TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_shime_date) ||'''))' ;
    END IF ;
-- 2008/10/27 mod start1.13�d�l�s��T_S_601 �\��˗��敪���\��̎��A���ߎ��{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_shime_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_shime_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where2 :=  lv_sql_shu_where2
      || ' AND TO_CHAR(xtc.tightening_date, '''
      || gc_date_fmt_hh24mi ||''') '||' >= '''|| gt_param.iv_shime_time_from ||''' ' ;
    END IF ;
-- 2008/10/27 mod start1.13�d�l�s��T_S_601 �\��˗��敪���\��̎��A���ߎ��{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_shime_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_shime_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_p ) THEN
-- 2008/10/27 mod end
      lv_sql_shu_where2 :=  lv_sql_shu_where2
      || ' AND TO_CHAR(xtc.tightening_date, '''
      || gc_date_fmt_hh24mi ||''') ' 
      || ' <= '''|| gt_param.iv_shime_time_to ||''' ' ;
    END IF ;
    ------------------------------------------------
    -- �󒍖��׃A�h�I��
    ------------------------------------------------
--
    lv_sql_shu_where2 :=  lv_sql_shu_where2
    || ' AND xoha.order_header_id = xola.order_header_id' ;
    lv_sql_shu_where2 :=  lv_sql_shu_where2
    || ' AND xola.delete_flag <> '''|| gc_delete_flg ||'''' 
    ------------------------------------------------
    -- OPM�i�ڏ��VIEW2
    ------------------------------------------------
    || ' AND xola.shipping_inventory_item_id = xim2v.inventory_item_id' 
    || ' AND xim2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xim2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xim2v.end_date_active >= xoha.schedule_ship_date' 
    || ' )' 
    ------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW4
    ------------------------------------------------
    || ' AND xim2v.item_id = xic4v.item_id' 
    || ' AND xic4v.prod_class_code = '''|| gv_prod_kbn ||''' ' ;
    IF ( gt_param.iv_item_kbn IS NOT NULL ) THEN
     lv_sql_shu_where2 :=   lv_sql_shu_where2 
     || ' AND xic4v.item_class_code = '''|| gt_param.iv_item_kbn ||''' ' ;
    END IF ;
    ------------------------------------------------
    -- �ړ����b�g�ڍ�(�A�h�I��)
    ------------------------------------------------
    lv_sql_shu_where2 :=  lv_sql_shu_where2 
    || ' AND xola.order_line_id = xmld.mov_line_id(+)' 
    || ' AND xmld.document_type_code(+) = ' || gc_doc_type_code_syukka 
    || ' AND xmld.record_type_code(+)   = ' || gc_rec_type_code_ins
    -------------------------------------------------------------------------------
    -- OPM���b�g�}�X�^
    -------------------------------------------------------------------------------
    || ' AND xmld.lot_id = ilm.lot_id(+) ' 
    || ' AND xmld.item_id = ilm.item_id(+) ' 
    ------------------------------------------------
    -- ���[�U���
    ------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id ' 
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '
    || gc_user_kbn_inside ||' ' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||''' ' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' OR' 
    || ' xoha.freight_carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xoha.freight_carrier_code = papf.attribute5 '
-- 2008/07/09 add S.Takemoto start
    -- �]�ƈ��敪��'�O��'�ŁA��^���敪���Ώۣ�܂��͢�����o�̓t���O���Ώۣ�̏ꍇ�A�o�͑ΏۊO
    || ' AND' 
    || ' xoha.freight_charge_class =''' || gc_freight_charge_code_1 || ''''       -- �^���敪
    || ' AND' 
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- �����o�͋敪
-- 2008/07/09 add S.Takemoto end
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' 
--mod start 1.2
--    || ' UNION ALL' ;
    ;
    lb_union := true;
  END IF;
--mod end 1.2
--
--add start 1.2
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_shikyu) = gc_biz_type_cd_shikyu) THEN
    IF (lb_union) THEN
      lv_sql_sik_sel_from1 := ' UNION ALL' ;
    END IF;
--add end 1.2
    lv_sql_sik_sel_from1  :=  lv_sql_sik_sel_from1
    --=====================================================================
    -- �x�����
    --=====================================================================
    || ' SELECT' 
    || ' '''|| gc_biz_type_nm_shik ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_shikyu ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v.distribution_block AS dist_block' 
    || ' ,xoha.freight_carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xoha.deliver_from AS deliver_from ' 
    || ' ,xil2v.description AS description ' 
    || ' ,xoha.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,xic4v.item_class_code AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,xic4v.item_class_name AS item_class_name ' 
    || ' ,DECODE(xoha.new_modify_flg, '''
      || gc_new_modify_flg_mod ||''', '''
      || gc_asterisk ||''') AS new_modify_flg ' 
    || ' ,xoha.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xoha.delivery_no AS delivery_no ' 
    || ' ,xoha.shipping_method_code AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
--mod start 1.10.2
--    || ' ,xoha.head_sales_branch AS head_sales_branch ' 
    || ' ,xoha.vendor_code AS head_sales_branch ' 
--mod end 1.10.2
    || ' ,xv2v.vendor_full_name AS party_name ' 
--mod start 1.10.2
--    || ' ,xoha.deliver_to AS deliver_to ' 
    || ' ,xoha.vendor_site_code AS deliver_to ' 
--mod end 1.10.2
    || ' ,xvs2v.vendor_site_name AS party_site_full_name ' 
    || ' ,xvs2v.address_line1 AS address_line1 ' 
    || ' ,xvs2v.address_line2 AS address_line2 ' 
    || ' ,xvs2v.phone AS phone ' 
    || ' ,xoha.arrival_time_from AS arrival_time_from ' 
    || ' ,xoha.arrival_time_to AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,xoha.request_no AS req_mov_no ' 
    || ' ,CASE' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xoha.sum_weight' 
    || ' ELSE' 
    || ' xoha.sum_capacity' 
    || ' END AS sum_weightm_capacity' 
    || ' ,CASE' 
    || ' WHEN ( xoha.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' '''|| gv_uom_weight ||'''' 
    || ' ELSE' 
    || ' '''|| gv_uom_capacity ||'''' 
    || ' END AS sum_weightm_capacity_t' 
    || ' ,NULL AS tehai_no ' 
    || ' ,xoha.prev_delivery_no AS prev_delivery_no ' ;
--
    lv_sql_sik_sel_from2  :=  lv_sql_sik_sel_from2
    || ' ,xoha.cust_po_number AS po_no ' 
    || ' ,NULL AS jpr_user_code ' 
    || ' ,xoha.collected_pallet_qty AS collected_pallet_qty ' 
    || ' ,xoha.shipping_instructions AS shipping_instructions ' 
    || ' ,xoha.slip_number AS slip_number ' 
    || ' ,xoha.small_quantity AS small_quantity ' 
    || ' ,xola.shipping_item_code AS item_code ' 
    || ' ,xim2v.item_short_name AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,xmld.lot_id AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,xmld.lot_no AS lot_no ' 
    || ' ,ilm.attribute1 AS attribute1 ' 
    || ' ,ilm.attribute3 AS attribute3 ' 
    || ' ,ilm.attribute2 AS attribute2 ' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' xim2v.num_of_cases' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_material ||''' ' 
    || ' OR xic4v.item_class_code = '''|| gc_item_cd_prdct_half ||''' )' 
    || ' AND ilm.attribute6 IS NOT NULL ) THEN' 
    || ' ilm.attribute6' 
    || ' WHEN ilm.attribute6 IS NULL THEN' 
    || ' xim2v.frequent_qty' 
    || ' END  AS num_of_cases' 
    || ' ,xim2v.net  AS net' 
    || ' ,CASE ' 
    || ' WHEN (xola.reserved_quantity > 0) THEN ' 
    || ' xmld.actual_quantity ' 
    || ' WHEN ( ( xola.reserved_quantity IS NULL ) ' 
    || ' OR ( xola.reserved_quantity = 0 ) ) THEN ' 
    || ' xola.quantity ' 
    || ' END AS qty ' 
-- 2008/10/27 mod start 1.13 �ۑ�32 �P��/�������Z���W�b�N�C��
--    || ' ,xim2v.item_um AS conv_unit '
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '|| gc_item_cd_prdct ||' )' 
    || ' AND ( xim2v.num_of_cases > 0 ) ' 
    || ' AND ( xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xim2v.conv_unit' 
    || ' ELSE' 
    || ' xim2v.item_um' 
    || ' END  AS conv_unit' 
-- 2008/10/27 mod end 1.13 
    || ' FROM' 
    || ' xxwsh_carriers_schedule xcs '            -- �z�Ԕz���v��(�A�h�I��)
    || ' ,xxwsh_order_headers_all xoha '          -- �󒍃w�b�_�A�h�I��
    || ' ,xxwsh_oe_transaction_types2_v xott2v '  -- �󒍃^�C�v���VIEW2
    || ' ,xxwsh_order_lines_all xola '            -- �󒍖��׃A�h�I��
    || ' ,xxinv_mov_lot_details xmld '            -- �ړ����b�g�ڍ�(�A�h�I��)
    || ' ,ic_lots_mst ilm '                       -- OPM���b�g�}�X�^
    || ' ,xxcmn_item_locations2_v xil2v '         -- OPM�ۊǏꏊ���VIEW2
    || ' ,xxcmn_vendor_sites2_v xvs2v '           -- �d����T�C�g���VIEW2
    || ' ,xxcmn_vendors2_v xv2v '                 -- �d������VIEW2
    || ' ,xxcmn_carriers2_v xc2v '                -- �^���Ǝҏ��VIEW2
    || ' ,xxcmn_item_mst2_v xim2v '               -- OPM�i�ڏ��VIEW2
    || ' ,xxcmn_item_categories4_v xic4v '        -- OPM�i�ڃJ�e�S���������VIEW4
    || ' ,fnd_user fu '                           -- ���[�U�[�}�X�^
    || ' ,per_all_people_f papf '                 -- �]�ƈ��}�X�^
    || ' ,xxwsh_ship_method2_v xsm2v ' ;          -- �z���敪���VIEW2
--
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- �󒍃w�b�_�A�h�I��
    -------------------------------------------------------------------------------
    IF ( gt_param.iv_mov_num IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' xoha.request_no = '''|| gt_param.iv_mov_num ||''' AND ' ;
    END IF ;
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || '     xoha.req_status >= '''|| gc_req_status_juryozumi ||'''' 
    || ' AND xoha.req_status <> '''|| gc_ship_status_delete ||'''' 
    || ' AND xoha.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xoha.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xoha.freight_carrier_code = '''|| gt_param.iv_freight_carrier_code||'''' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_date IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND TRUNC(TO_DATE(xoha.notif_date, '''|| gc_date_fmt_all ||'''))' 
      || ' = TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_notif_date) ||''', '''
                              || gc_date_fmt_all ||'''))' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND TO_CHAR(xoha.notif_date, '''|| gc_date_fmt_hh24mi ||''') >= '''
      || gt_param.iv_notif_time_from ||'''' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND TO_CHAR(xoha.notif_date, '''|| gc_date_fmt_hh24mi ||''') <= '''
      || gt_param.iv_notif_time_to ||'''' ;
    END IF ;
-- 2008/07/09 mod S.Takemoto start
--    lv_sql_sik_where1 :=  lv_sql_sik_where1
--    || ' AND xoha.instruction_dept = '''|| gt_param.iv_dept ||'''' 
    IF ( gt_param.iv_dept IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xoha.instruction_dept = '''|| gt_param.iv_dept ||'''' ;
    END IF;
--
    lv_sql_sik_where1 :=  lv_sql_sik_where1
-- 2008/07/09 mod S.Takemoto end
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_p ||'''' 
    || ' AND' 
    || ' xoha.notif_status IN ('''|| gc_fixa_notif_yet ||''', '''|| gc_fixa_notif_re ||''')' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_d ||'''' 
    || ' AND' 
    || ' xoha.notif_status = '''|| gc_fixa_notif_end ||'''' 
    || ' )' 
    || ' )' 
    || ' AND xoha.latest_external_flag = '''|| gc_latest_external_flag ||''''
    -------------------------------------------------------------------------------
    -- �z�Ԕz���v��(�A�h�I��)
    -------------------------------------------------------------------------------
    || ' AND xoha.delivery_no = xcs.delivery_no(+)' 
    -------------------------------------------------------------------------------
    -- �z���敪���VIEW2
    -------------------------------------------------------------------------------
    || ' AND xoha.shipping_method_code = xsm2v.ship_method_code(+)'  -- 6/23 �O�������ǉ�
    ------------------------------------------------
    -- �󒍃^�C�v���VIEW2
    ------------------------------------------------
    || ' AND xoha.order_type_id = xott2v.transaction_type_id' ;
    IF ( gt_param.iv_shukko_keitai IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xott2v.transaction_type_id = '''|| gt_param.iv_shukko_keitai ||'''' ;
    END IF ;
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || ' AND xott2v.shipping_shikyu_class = '''|| gc_ship_pro_kbn_sik ||'''' 
    || ' AND xott2v.order_category_code <> '''|| gc_order_cate_ret ||'''' 
    ------------------------------------------------
    -- OPM�ۊǏꏊ���VIEW2
    ------------------------------------------------
    || ' AND xoha.deliver_from_id = xil2v.inventory_location_id' ;
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1
      || ' AND xil2v.eos_control_type = '''
      || gt_param.iv_online_kbn ||'''' ;
    END IF ;
-- 2008/10/27 add start 1.13 T_TE080_BPO_620�w�E47 �o�ɔz���敪���o�ɂ̏ꍇ�A�q�Ɍ��^���Ǝ҂����O
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_sik_where1 :=  lv_sql_sik_where1 
      || ' AND ( xil2v.eos_detination <> xc2v.eos_detination ) ' ;
    END IF ;
-- 2008/10/27 add end 1.13 
    lv_sql_sik_where1 :=  lv_sql_sik_where1
    || ' AND (' 
    || ' xil2v.distribution_block IN ('''|| gt_param.iv_block1 ||''', '''
      || gt_param.iv_block2 ||''', '''
      || gt_param.iv_block3 ||''')' 
    || ' OR' 
    || ' xoha.deliver_from = '''|| gt_param.iv_shipped_locat_code ||'''' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL ' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL ' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL ' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    -------------------------------------------------------------------------------
    -- �d����T�C�g���VIEW2
    -------------------------------------------------------------------------------
    || ' AND xoha.vendor_site_id = xvs2v.vendor_site_id' 
    || ' AND xvs2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xvs2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xvs2v.end_date_active IS NULL' 
    || ' )' ;
    -------------------------------------------------------------------------------
    -- �d������VIEW2
    -------------------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- �Ǌ����_
    -- �Ǌ����_�i���́j
--
    lv_sql_sik_where2 :=  lv_sql_sik_where2
    || ' AND xoha.vendor_id = xv2v.vendor_id' 
    || ' AND xv2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xv2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xv2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    ------------------------------------------------
    -- �^���Ǝҏ��VIEW2
    ------------------------------------------------
    ----------------------------------------------------------------------
    -- �^���Ǝ�
    -- �^���Ǝҁi���́j
    || ' AND xoha.career_id = xc2v.party_id(+)' 
    || ' AND (' 
    || ' xc2v.start_date_active <= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xc2v.start_date_active IS NULL' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xc2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||''' ' 
    || ' AND' 
    || ' xoha.freight_carrier_code <> xoha.deliver_from' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||''' ' 
    || ' )' 
    ------------------------------------------------
    -- �󒍖��׃A�h�I��
    ------------------------------------------------
    || ' AND xoha.order_header_id = xola.order_header_id' 
    || ' AND xola.delete_flag <> '''|| gc_delete_flg ||'''' 
    ------------------------------------------------
    -- OPM�i�ڏ��VIEW2
    ------------------------------------------------
    || ' AND xola.shipping_inventory_item_id = xim2v.inventory_item_id '
    || ' AND xim2v.start_date_active <= xoha.schedule_ship_date' 
    || ' AND (' 
    || ' xim2v.end_date_active >= xoha.schedule_ship_date' 
    || ' OR' 
    || ' xim2v.end_date_active IS NULL' 
    || ' )' 
    ------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW4
    ------------------------------------------------
    || ' AND xim2v.item_id = xic4v.item_id' 
    || ' AND xic4v.prod_class_code = ''' || gv_prod_kbn ||'''' ;
    IF ( gt_param.iv_item_kbn IS NOT NULL ) THEN
      lv_sql_sik_where2 :=  lv_sql_sik_where2
      || ' AND xic4v.item_class_code = '''|| gt_param.iv_item_kbn ||'''' ;
    END IF ;
    lv_sql_sik_where2 :=  lv_sql_sik_where2
    ------------------------------------------------
    -- �ړ����b�g�ڍ�(�A�h�I��)
    ------------------------------------------------
    || ' AND xola.order_line_id = xmld.mov_line_id(+)' 
    || ' AND xmld.document_type_code(+) = ' || gc_doc_type_code_shikyu
    || ' AND xmld.record_type_code(+)   = ' || gc_rec_type_code_ins
    -------------------------------------------------------------------------------
    -- OPM���b�g�}�X�^
    -------------------------------------------------------------------------------
    || ' AND xmld.lot_id = ilm.lot_id(+) ' 
    || ' AND xmld.item_id = ilm.item_id(+) ' 
    ------------------------------------------------
    -- ���[�U���
    ------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id' 
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '''|| gc_user_kbn_inside ||'''' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||'''' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v.purchase_code = papf.attribute4 ' 
    || ' OR' 
    || ' xoha.freight_carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xoha.freight_carrier_code = papf.attribute5 ' 
-- 2008/07/09 add S.Takemoto start
    -- �]�ƈ��敪��'�O��'�ŁA��^���敪���Ώۣ�܂��͢�����o�̓t���O���Ώۣ�̏ꍇ�A�o�͑ΏۊO
    || ' AND'
    || ' xoha.freight_charge_class =''' || gc_freight_charge_code_1 || ''''       -- �^���敪
    || ' AND'
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- �����o�͋敪
-- 2008/07/09 add S.Takemoto end
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' 
--mod start 1.2
--    || ' UNION ALL' ;
    ;
    lb_union := true;
  END IF;
--mod end 1.2
--
--add start 1.2
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_move) = gc_biz_type_cd_move) THEN
    IF (lb_union) THEN
      lv_sql_ido_sel_from1 := ' UNION ALL' ;
    END IF;
--add end 1.2
    lv_sql_ido_sel_from1  :=  lv_sql_ido_sel_from1
    --=====================================================================
    -- �ړ����
    --=====================================================================
    || ' SELECT' 
    || ' '''|| gc_biz_type_nm_move ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_move ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v1.distribution_block AS dist_block' 
    || ' ,xmrih.freight_carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xmrih.shipped_locat_code AS deliver_from ' 
    || ' ,xil2v1.description AS description ' 
    || ' ,xmrih.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,xic4v.item_class_code AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,xic4v.item_class_name AS item_class_name ' 
    || ' ,DECODE(xmrih.new_modify_flg, '''
      || gc_new_modify_flg_mod ||''', '''
      || gc_asterisk ||''', NULL) AS new_modify_flg ' 
    || ' ,xmrih.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xmrih.delivery_no AS delivery_no ' 
    || ' ,xmrih.shipping_method_code AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
    || ' ,NULL AS head_sales_branch ' 
    || ' ,NULL AS party_name ' 
    || ' ,xmrih.ship_to_locat_code AS deliver_to ' 
    || ' ,xil2v2.description AS party_site_full_name ' 
    || ' ,xl2v.address_line1 AS address_line1 ' 
    || ' ,NULL AS address_line2 ' 
    || ' ,xl2v.phone AS phone ' 
    || ' ,xmrih.arrival_time_from AS arrival_time_from ' 
    || ' ,xmrih.arrival_time_to AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,xmrih.mov_num AS req_mov_no ' 
    || ' ,CASE' 
    || ' WHEN ( xsm2v.small_amount_class = '''|| gc_small_amount_enabled ||''' ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xmrih.sum_weight' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN' 
    || ' xmrih.sum_capacity' 
    || ' END'
    || ' WHEN  xsm2v.small_amount_class IS NULL THEN'   -- 6/23 �ǉ�
    || ' NULL'
    || ' ELSE' 
    || ' CASE ' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''' ) THEN' 
    || ' xmril.pallet_weight + xmrih.sum_weight' 
    || ' WHEN ( xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_c ||''' ) THEN' 
    || ' xmril.pallet_weight + xmrih.sum_capacity' 
    || ' END' 
    || ' END AS sum_weightm_capacity' 
    || ' ,CASE' 
    || ' WHEN (xmrih.weight_capacity_class = '''|| gc_wei_cap_kbn_w ||''') THEN' 
    || ' '''|| gv_uom_weight ||'''' 
    || ' ELSE' 
    || ' '''|| gv_uom_capacity ||'''' 
    || ' END AS sum_weightm_capacity_t ' 
    || ' ,xmrih.batch_no AS tehai_no ' 
    || ' ,xmrih.prev_delivery_no AS prev_delivery_no ' 
    || ' ,NULL AS po_no ' 
    || ' ,NULL AS jpr_user_code ' ;
--
    lv_sql_ido_sel_from2  :=  lv_sql_ido_sel_from2
    || ' ,xmrih.collected_pallet_qty AS collected_pallet_qty ' 
    || ' ,xmrih.description AS shipping_instructions ' 
    || ' ,xmrih.slip_number AS slip_number ' 
    || ' ,xmrih.small_quantity AS small_quantity ' 
    || ' ,xmril.item_code AS item_code ' 
    || ' ,xim2v.item_short_name AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,xmld.lot_id AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,xmld.lot_no AS lot_no ' 
    || ' ,ilm.attribute1 AS attribute1 ' 
    || ' ,ilm.attribute3 AS attribute3 ' 
    || ' ,ilm.attribute2 AS attribute2 ' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' xim2v.num_of_cases' 
    || ' WHEN ( ( xic4v.item_class_code = '''|| gc_item_cd_material ||'''' 
    || ' OR xic4v.item_class_code = '''|| gc_item_cd_prdct_half ||''' )' 
    || ' AND ilm.attribute6 IS NOT NULL ) THEN' 
    || ' ilm.attribute6' 
    || ' WHEN ( ilm.attribute6 IS NULL ) THEN' 
    || ' xim2v.frequent_qty' 
    || ' END AS num_of_cases' 
    || ' ,xim2v.net AS net' 
    || ' ,CASE' 
    || ' WHEN ( xmril.reserved_quantity > 0 ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xic4v.prod_class_code = '''|| gc_prod_cd_drink ||'''' 
-- mod start 1.12
--    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||'''' 
    || ' AND xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xmld.actual_quantity / TO_NUMBER( '
    || ' CASE WHEN xim2v.num_of_cases > 0 '
    || ' THEN  xim2v.num_of_cases '
    || ' ELSE TO_CHAR(1) '
    || ' END)' 
    || ' ELSE' 
    || ' xmld.actual_quantity' 
    || ' END' 
    || ' WHEN ( ( xmril.reserved_quantity IS NULL )' 
    || ' OR (xmril.reserved_quantity = 0 ) ) THEN' 
    || ' CASE ' 
    || ' WHEN ( xic4v.prod_class_code = '''|| gc_prod_cd_drink ||'''' 
--    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||''' ) THEN' 
    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||'''' 
    || ' AND xim2v.conv_unit IS NOT NULL ) THEN' 
-- mod end 1.12
    || ' xmril.instruct_qty / TO_NUMBER( '
    || ' CASE WHEN xim2v.num_of_cases > 0 '
    || ' THEN  xim2v.num_of_cases '
    || ' ELSE TO_CHAR(1) '
    || ' END)' 
    || ' ELSE' 
    || ' xmril.instruct_qty' 
    || ' END' 
    || ' END AS qty' 
    || ' ,CASE' 
    || ' WHEN ( xic4v.prod_class_code = '''|| gc_prod_cd_drink ||'''' 
    || ' AND xic4v.item_class_code = '''|| gc_item_cd_prdct ||'''' 
-- 2008/10/27 add start 1.13 �ۑ�32 �P��/�������Z���W�b�N�C��
    || ' AND xim2v.num_of_cases > 0 ' 
-- 2008/10/27 add end 1.13 
    || ' AND xim2v.conv_unit IS NOT NULL ) THEN' 
    || ' xim2v.conv_unit' 
    || ' ELSE' 
    || ' xim2v.item_um' 
    || ' END AS conv_unit'
    || ' FROM' 
    || ' xxinv_mov_req_instr_headers xmrih '  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
    || ' ,xxinv_mov_req_instr_lines xmril '   -- �ړ��˗�/�w������(�A�h�I��)
    || ' ,xxwsh_carriers_schedule xcs '       -- �z�Ԕz���v��i�A�h�I���j
    || ' ,xxcmn_item_locations2_v xil2v1 '    -- OPM�ۊǏꏊ���VIEW2(�o)
    || ' ,xxcmn_item_locations2_v xil2v2 '    -- OPM�ۊǏꏊ���VIEW2(��)
    || ' ,xxcmn_locations2_v xl2v '           -- ���Ə����VIEW2
    || ' ,xxcmn_carriers2_v xc2v '            -- �^���Ǝҏ��VIEW2
    || ' ,xxcmn_item_mst2_v xim2v '           -- OPM�i�ڏ��VIEW2
    || ' ,xxcmn_item_categories4_v xic4v '    -- OPM�i�ڃJ�e�S���������VIEW4
    || ' ,xxinv_mov_lot_details xmld '        -- �ړ����b�g�ڍ�(�A�h�I��)
    || ' ,ic_lots_mst ilm '                   -- OPM���b�g�}�X�^
    || ' ,fnd_user fu '                       -- ���[�U�[�}�X�^
    || ' ,per_all_people_f papf '             -- �]�ƈ����VIEW2
    || ' ,xxwsh_ship_method2_v xsm2v ' ;      -- �z���敪���VIEW2
--
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- �ړ��˗�/�w���w�b�_(�A�h�I��)
    -------------------------------------------------------------------------------
    IF ( gt_param.iv_mov_num IS NOT NULL ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' xmrih.mov_num = '''|| gt_param.iv_mov_num ||''' AND ' ;
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || '     xmrih.mov_type <> '''|| gc_mov_type_not_ship ||''' ' 
    || ' AND xmrih.status >= '''|| gc_move_status_ordered ||'''' 
    || ' AND xmrih.status <> '''|| gc_move_status_not ||'''' 
    || ' AND xmrih.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xmrih.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_date IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_date IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND TRUNC(TO_DATE(xmrih.notif_date, '''|| gc_date_fmt_all ||'''))' 
      || ' = TRUNC(TO_DATE('''|| TRUNC(gt_param.iv_notif_date) ||''', '''
      || gc_date_fmt_all ||'''))' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_time_from IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_from IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND TO_CHAR(xmrih.notif_date, '''|| gc_date_fmt_hh24mi ||''') >= '''
      || gt_param.iv_notif_time_from ||'''' ;
    END IF ;
-- 2008/10/27 mod start1.13 �����w�E297 �\��˗��敪���m��̎��A�m��ʒm���{���A���Ԃ������Ƃ���
--    IF ( gt_param.iv_notif_time_to IS NOT NULL ) THEN
    IF ( gt_param.iv_notif_time_to IS NOT NULL 
      AND gt_param.iv_plan_decide_kbn = gc_plan_decide_d ) THEN
-- 2008/10/27 mod end
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND TO_CHAR(xmrih.notif_date, '''|| gc_date_fmt_hh24mi ||''') <= '''
      || gt_param.iv_notif_time_to ||'''' ;
    END IF ;
-- 2008/07/09 mod S.Takemoto start
--    lv_sql_ido_where1 :=  lv_sql_ido_where1
--    || ' AND xmrih.instruction_post_code = '''|| gt_param.iv_dept ||'''' ;
    IF ( gt_param.iv_dept IS NOT NULL ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND xmrih.instruction_post_code = '''|| gt_param.iv_dept ||'''' ;
    END IF;
-- 2008/07/09 mod S.Takemoto end
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      --2008/07/04 ST�s��Ή�#409
      --lv_sql_ido_where1 :=  lv_sql_ido_where1
      --|| ' AND xmrih.career_id = '''|| gt_param.iv_freight_carrier_code ||'''' ;
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND xmrih.freight_carrier_code = '''|| gt_param.iv_freight_carrier_code ||'''' ;
      --2008/07/04 ST�s��Ή�#409
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''
    || gc_plan_decide_p ||'''' 
    || ' AND' 
    || ' xmrih.notif_status IN ('''|| gc_fixa_notif_yet ||''', '''
      || gc_fixa_notif_re ||''')' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_plan_decide_kbn ||''' = '''|| gc_plan_decide_d ||'''' 
    || ' AND' 
    || ' xmrih.notif_status = '''|| gc_fixa_notif_end ||'''' 
    || ' )' 
    || ' )' 
    -------------------------------------------------------------------------------
    -- �z�Ԕz���v��(�A�h�I��)
    -------------------------------------------------------------------------------
    || ' AND xmrih.delivery_no = xcs.delivery_no(+)' 
    -------------------------------------------------------------------------------
    -- �z���敪���VIEW2
    -------------------------------------------------------------------------------
    || ' AND xmrih.shipping_method_code = xsm2v.ship_method_code(+)'  -- 6/23 �O�������ǉ�
    -------------------------------------------------------------------------------
    -- OPM�ۊǏꏊ�}�X�^�i�o�j
    -------------------------------------------------------------------------------
    || ' AND xmrih.shipped_locat_id = xil2v1.inventory_location_id' ;
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1
      || ' AND xil2v1.eos_control_type = '''|| gt_param.iv_online_kbn ||'''' ;
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1
    || ' AND (' 
    || ' xil2v1.distribution_block IN ('''|| gt_param.iv_block1 ||''', '''
      || gt_param.iv_block2 ||''', '''
      || gt_param.iv_block3 ||''')' 
    || ' OR' 
    || ' xmrih.shipped_locat_code = '''
    || gt_param.iv_shipped_locat_code ||'''' 
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    -------------------------------------------------------------------------------
    -- OPM�ۊǏꏊ�}�X�^�i���j
    -------------------------------------------------------------------------------
    || ' AND xmrih.ship_to_locat_id = xil2v2.inventory_location_id' 
-- 2008/10/27 add start 1.13 T_TE080_BPO_620�w�E47 �o�ɔz���敪���o�ɂ̏ꍇ�A�q�Ɍ��^���Ǝ҂����O
    ;
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_ido_where1 :=  lv_sql_ido_where1 
      || ' AND ( xil2v1.eos_detination <> xc2v.eos_detination ) ' ;
    END IF ;
    lv_sql_ido_where1 :=  lv_sql_ido_where1 
-- 2008/10/27 add end 1.13 
    -------------------------------------------------------------------------------
    -- ���Ə����VIEW2
    -------------------------------------------------------------------------------
    || ' AND xil2v2.location_id = xl2v.location_id' 
    || ' AND xl2v.start_date_active <= xmrih.schedule_ship_date' 
    || ' AND (' 
    || ' xl2v.end_date_active >= xmrih.schedule_ship_date' 
    || ' OR' 
    || ' xl2v.end_date_active IS NULL' 
    || ' )' ;
    -------------------------------------------------------------------------------
    -- �^���Ǝҏ��VIEW2
    -------------------------------------------------------------------------------
    ----------------------------------------------------------------------
    -- �^���Ǝ�
    -- �^���Ǝҁi���́j
--
    lv_sql_ido_where2 :=  lv_sql_ido_where2 
    || ' AND xmrih.career_id = xc2v.party_id(+)' 
    || ' AND (' 
    || ' xc2v.start_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.start_date_active <= xmrih.schedule_ship_date' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active >= xmrih.schedule_ship_date' 
    || ' OR' 
    || ' xc2v.end_date_active IS NULL' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||'''' 
    || ' AND' 
    || ' xmrih.freight_carrier_code <> xmrih.shipped_locat_code' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||'''' 
    || ' )' 
    -------------------------------------------------------------------------------
    -- �ړ��˗�/�w������(�A�h�I��)
    -------------------------------------------------------------------------------
    || ' AND xmrih.mov_hdr_id = xmril.mov_hdr_id' 
    || ' AND xmril.delete_flg <> '''|| gc_delete_flg ||'''' 
    -------------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW2
    -------------------------------------------------------------------------------
    || ' AND xmril.item_id = xim2v.item_id' 
    || ' AND xim2v.start_date_active <= xmrih.schedule_ship_date' 
    || ' AND (' 
    || ' xim2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xim2v.end_date_active >= xmrih.schedule_ship_date' 
    || ' )' 
--
    -------------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW4
    -------------------------------------------------------------------------------
    || ' AND xim2v.item_id = xic4v.item_id' 
    || ' AND xic4v.prod_class_code = '''|| gv_prod_kbn ||'''' ;
    IF ( gt_param.iv_item_kbn IS NOT NULL ) THEN
      lv_sql_ido_where2 :=  lv_sql_ido_where2 
      || ' AND xic4v.item_class_code = '''
      || gt_param.iv_item_kbn ||'''' ;
    END IF ;
    -------------------------------------------------------------------------------
    -- �ړ����b�g�ڍ�(�A�h�I��)
    -------------------------------------------------------------------------------
    lv_sql_ido_where2 :=  lv_sql_ido_where2
    || ' AND xmril.mov_line_id = xmld.mov_line_id(+)' 
    || ' AND xmld.document_type_code(+) = ' || gc_doc_type_code_mv
    || ' AND xmld.record_type_code(+)   = ' || gc_rec_type_code_ins
    -------------------------------------------------------------------------------
    -- OPM���b�g�}�X�^
    -------------------------------------------------------------------------------
    || ' AND xmld.lot_id = ilm.lot_id(+) ' 
    || ' AND xmld.item_id = ilm.item_id(+) ' 
    -------------------------------------------------------------------------------
    -- ���[�U���
    -------------------------------------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id '
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '''|| gc_user_kbn_inside ||''''
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||'''' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v1.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v1.purchase_code = papf.attribute4 '
    || ' OR' 
    || ' xmrih.freight_carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xmrih.freight_carrier_code = papf.attribute5 ' 
-- 2008/07/09 add S.Takemoto start
    -- �]�ƈ��敪��'�O��'�ŁA��^���敪���Ώۣ�܂��͢�����o�̓t���O���Ώۣ�̏ꍇ�A�o�͑ΏۊO
    || ' AND' 
    || ' xmrih.freight_charge_class =''' || gc_freight_charge_code_1 || ''''       -- �^���敪
    || ' AND' 
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- �����o�͋敪
-- 2008/07/09 add S.Takemoto end
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' ;
--add start 1.2
  END IF;
--add end 1.2
-- 2008/07/09 add S.Takemoto start
  IF (NVL(gt_param.iv_gyoumu_shubetsu,gc_biz_type_cd_etc) = gc_biz_type_cd_etc) THEN
    IF (lb_union) THEN
      lv_sql_etc_sel_from1 := ' UNION ALL' ;
    END IF;
--
    lv_sql_etc_sel_from1  :=  lv_sql_etc_sel_from1
    --=====================================================================
    -- ���̑����
    --=====================================================================
    || ' SELECT' 
    || ' '''|| gc_biz_type_nm_etc ||''' AS gyoumu_shubetsu ' 
    || ' ,'''|| gc_biz_type_cd_etc ||''' AS gyoumu_shubetsu_code ' 
    || ' ,xil2v1.distribution_block AS dist_block' 
    || ' ,xcs.carrier_code AS freight_carrier_code ' 
    || ' ,xc2v.party_name AS carrier_full_name '
    || ' ,xcs.deliver_from AS deliver_from ' 
    || ' ,xil2v1.description AS description ' 
    || ' ,xcs.schedule_ship_date AS schedule_ship_date ' 
-- 2008/10/27 ADD start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,NULL AS item_class_code ' 
-- 2008/10/27 ADD end 1.13 
    || ' ,NULL AS item_class_name ' 
    || ' ,NULL AS new_modify_flg ' 
    || ' ,xcs.schedule_arrival_date AS schedule_arrival_date' 
    || ' ,xcs.delivery_no AS delivery_no ' 
    || ' ,xcs.delivery_type AS shipping_method_code ' 
    || ' ,xsm2v.ship_method_meaning AS ship_method_meaning ' 
    || ' ,NULL AS head_sales_branch ' 
    || ' ,NULL AS party_name ' 
    || ' ,xcs.deliver_to AS deliver_to ' 
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:���_
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:�ڋq
    || ' xcas2v.party_site_full_name'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:�x����
    || ' xvs2v.vendor_site_name'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:�ړ�
    || ' xil2v2.description'
    || ' END AS party_site_full_name'
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:���_
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:�ڋq
    || ' xcas2v.address_line1'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:�x����
    || ' xvs2v.address_line1'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:�ړ�
    || ' xl2v.address_line1'
    || ' END AS address_line1'
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:���_
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:�ڋq
    || ' xcas2v.address_line2'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:�x����
    || ' xvs2v.address_line2'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:�ړ�
    || ' NULL'
    || ' END AS address_line2'
    || ' ,CASE'
    || ' WHEN ( xcs.deliver_to_code_class IN ('''|| gc_deliver_to_class_1 ||''''         -- 1:���_
                                       || ' ,''' || gc_deliver_to_class_10 ||''' )) THEN' -- 10:�ڋq
    || ' xcas2v.phone'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_11 ||''' ) THEN'   -- 11:�x����
    || ' xvs2v.phone'
    || ' WHEN ( xcs.deliver_to_code_class = '''|| gc_deliver_to_class_4 ||''' ) THEN'    -- 4:�ړ�
    || ' xl2v.phone'
    || ' END AS phone'
    || ' ,NULL AS arrival_time_from ' 
    || ' ,NULL AS arrival_time_to ' 
    || ' ,xcs.sum_loading_capacity AS sum_loading_capacity ' 
    || ' ,xcs.sum_loading_weight AS sum_loading_weight ' 
    || ' ,NULL AS req_mov_no ' 
    || ' ,NULL AS sum_weightm_capacity' 
    || ' ,NULL AS sum_weightm_capacity_t ' 
--
    || ' ,NULL AS tehai_no ' 
    || ' ,NULL AS prev_delivery_no ' 
    || ' ,NULL AS po_no ' 
    || ' ,NULL AS jpr_user_code ' ;
--
    lv_sql_etc_sel_from2  :=  lv_sql_etc_sel_from2
    || ' ,NULL AS collected_pallet_qty ' 
    || ' ,NULL AS shipping_instructions ' 
    || ' ,xcs.slip_number AS slip_number ' 
    || ' ,xcs.small_quantity AS small_quantity ' 
    || ' ,NULL AS item_code ' 
    || ' ,NULL AS item_name ' 
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
    || ' ,NULL AS lot_id ' 
-- 2008/10/27 mod end 1.13 
    || ' ,NULL AS lot_no ' 
    || ' ,NULL AS attribute1 ' 
    || ' ,NULL AS attribute3 ' 
    || ' ,NULL AS attribute2 ' 
    || ' ,NULL AS num_of_cases' 
    || ' ,NULL AS net' 
    || ' ,NULL AS qty' 
    || ' ,NULL AS conv_unit'
    || ' FROM' 
    || ' xxwsh_carriers_schedule xcs '        -- �z�Ԕz���v��i�A�h�I���j
    || ' ,xxcmn_item_locations2_v xil2v1 '    -- OPM�ۊǏꏊ���VIEW2(�o)
    || ' ,xxcmn_cust_acct_sites2_v xcas2v '   -- �ڋq�T�C�g���VIEW2
    || ' ,xxcmn_vendor_sites2_v xvs2v '       -- �d����T�C�g���VIEW2
    || ' ,xxcmn_item_locations2_v xil2v2 '    -- OPM�ۊǏꏊ���VIEW2(��)
    || ' ,xxcmn_locations2_v xl2v '           -- ���Ə����VIEW2
    || ' ,xxcmn_carriers2_v xc2v '            -- �^���Ǝҏ��VIEW2
    || ' ,fnd_user fu '                       -- ���[�U�[�}�X�^
    || ' ,per_all_people_f papf '             -- �]�ƈ����VIEW2
    || ' ,xxwsh_ship_method2_v xsm2v ' ;      -- �z���敪���VIEW2
--
    lv_sql_etc_where1 :=  lv_sql_etc_where1
    || ' WHERE' ;
    -------------------------------------------------------------------------------
    -- �z�Ԕz���v��A�h�I��
    -------------------------------------------------------------------------------
    lv_sql_etc_where1 :=  lv_sql_etc_where1 
    || ' xcs.non_slip_class ='''|| gc_non_slip_class_2 ||''''            --�`�[�Ȃ��z�ԋ敪 2�F�`�[�Ȃ��z��
    || ' AND xcs.deliver_to_code_class IN('''|| gc_deliver_to_class_1  ||'''' -- 1:���_
                               || ' ,''' || gc_deliver_to_class_4  ||''''     -- 4:�ړ�
                               || ' ,''' || gc_deliver_to_class_10 ||''''     -- 10:�ڋq
                               || ' ,''' || gc_deliver_to_class_11 ||''')'    -- 11:�x����
    || ' AND xcs.schedule_ship_date >= '''|| TRUNC(gt_param.iv_ship_from) ||'''' 
    || ' AND xcs.schedule_ship_date <= '''|| TRUNC(gt_param.iv_ship_to) ||'''' ;
    IF ( gt_param.iv_freight_carrier_code IS NOT NULL ) THEN
      lv_sql_etc_where1 :=  lv_sql_etc_where1 
      || ' AND ( xcs.carrier_code = '''|| gt_param.iv_freight_carrier_code ||''')' ;
    END IF ;
-- 2008/07/29 add S.Takemoto start
    lv_sql_etc_where1 :=  lv_sql_etc_where1 
    || ' AND xcs.prod_class ='''|| gv_prod_kbn ||'''' ;
-- 2008/07/29 add S.Takemoto end
    -------------------------------------------------------------------------------
    -- �z���敪���VIEW2
    -------------------------------------------------------------------------------
    lv_sql_etc_where1 :=  lv_sql_etc_where1
    || ' AND xcs.delivery_type = xsm2v.ship_method_code'  -- �z���敪
    || ' AND xcs.schedule_ship_date'                 --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
    || ' BETWEEN xsm2v.start_date_active'
    || ' AND NVL(xsm2v.end_date_active , xcs.schedule_ship_date)'
    ------------------------------------------------
    -- OPM�ۊǏꏊ���VIEW2
    ------------------------------------------------
    || ' AND xcs.deliver_from_id = xil2v1.inventory_location_id';
    IF ( gt_param.iv_online_kbn IS NOT NULL ) THEN
      lv_sql_etc_where1 :=  lv_sql_etc_where1
      || ' AND xil2v1.eos_control_type = '''|| gt_param.iv_online_kbn ||'''' ;
    END IF ;
-- 2008/10/27 add start 1.13 T_TE080_BPO_620�w�E47 �o�ɔz���敪���o�ɂ̏ꍇ�A�q�Ɍ��^���Ǝ҂����O
    IF ( gt_param.iv_shukko_haisou_kbn = gc_shukko_haisou_kbn_d ) THEN
      lv_sql_etc_where1 :=  lv_sql_etc_where1 
      || ' AND ( xil2v1.eos_detination <> xc2v.eos_detination ) ' ;
    END IF ;
-- 2008/10/27 add end 1.13 
    lv_sql_etc_where1 :=  lv_sql_etc_where1
    || ' AND (' 
    || ' xil2v1.distribution_block IN ( '''|| gt_param.iv_block1 ||'''' 
    || '  , '''|| gt_param.iv_block2 ||'''' 
    || '  , '''|| gt_param.iv_block3 ||''' )' 
    || ' OR' 
    || ' xcs.deliver_from = '''|| gt_param.iv_shipped_locat_code ||''' '
    || ' OR' 
    || ' (' 
    || ' '''|| gt_param.iv_block1 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block2 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_block3 ||''' IS NULL' 
    || ' AND' 
    || ' '''|| gt_param.iv_shipped_locat_code ||''' IS NULL' 
    || ' )' 
    || ' )' 
    ------------------------------------------------
    -- �ڋq�T�C�g���VIEW2
    ------------------------------------------------
    || ' AND xcs.deliver_to_id = xcas2v.party_site_id(+)' 
    || ' AND xcas2v.start_date_active(+) <= xcs.schedule_ship_date' 
    || ' AND xcas2v.end_date_active(+) >= xcs.schedule_ship_date'
    -------------------------------------------------------------------------------
    -- �d����T�C�g���VIEW2
    -------------------------------------------------------------------------------
    || ' AND xcs.deliver_to_id = xvs2v.vendor_site_id(+)' 
    || ' AND xvs2v.start_date_active(+) <= xcs.schedule_ship_date' 
    || ' AND xvs2v.end_date_active(+) >= xcs.schedule_ship_date' 
    -------------------------------------------------------------------------------
    -- OPM�ۊǏꏊ�}�X�^�i���j
    -------------------------------------------------------------------------------
    || ' AND xcs.deliver_to_id = xil2v2.inventory_location_id(+)' 
    -------------------------------------------------------------------------------
    -- ���Ə����VIEW2
    -------------------------------------------------------------------------------
    || ' AND xil2v2.location_id = xl2v.location_id(+)' 
    || ' AND ( xcs.schedule_ship_date'                 --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
    || ' BETWEEN xl2v.start_date_active'
    || ' AND NVL(xl2v.end_date_active , xcs.schedule_ship_date)'
    || ' OR xil2v2.location_id IS NULL'  --�܂��́A���Ə���񖢑��� �O�������Ƃ��邽��
    || ' )' ;
    ------------------------------------------------
    -- �^���Ǝҏ��VIEW2
    ------------------------------------------------
    ----------------------------------------------------------------------
    -- �^���Ǝ�
    -- �^���Ǝҁi���́j
    lv_sql_etc_where2 :=  lv_sql_etc_where2
    || ' AND xcs.carrier_id = xc2v.party_id' 
    || ' AND (' 
    || ' xc2v.start_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.start_date_active <= xcs.schedule_ship_date' 
    || ' )' 
    || ' AND (' 
    || ' xc2v.end_date_active IS NULL' 
    || ' OR' 
    || ' xc2v.end_date_active >= xcs.schedule_ship_date' 
    || ' )' 
    ----------------------------------------------------------------------
    || ' AND (' 
    || ' (' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_d ||''' '
    || ' AND' 
    || ' xcs.carrier_code <> xcs.deliver_from' 
    || ' )' 
    || ' OR' 
    || ' '''|| gt_param.iv_shukko_haisou_kbn ||''' = '''|| gc_shukko_haisou_kbn_p ||''' '
    || ' )' 
    ------------------------------------------------
    -- ���[�U���
    ------------------------------------------------
    || ' AND fu.user_id = '''|| FND_GLOBAL.USER_ID ||'''' 
    || ' AND fu.employee_id = papf.person_id' 
    || ' AND (' 
    || ' NVL(papf.attribute3, '''|| gc_user_kbn_inside ||''') = '''|| gc_user_kbn_inside ||'''' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute3 = '''|| gc_user_kbn_outside ||'''' 
    || ' AND' 
    || ' (' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NULL ' 
    || ' AND' 
    || ' xil2v1.purchase_code = papf.attribute4 ' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NOT NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' (' 
    || ' xil2v1.purchase_code = papf.attribute4 ' 
    || ' OR' 
    || ' xcs.carrier_code = papf.attribute5 ' 
    || ' )' 
    || ' )' 
    || ' OR' 
    || ' (' 
    || ' papf.attribute4 IS NULL ' 
    || ' AND' 
    || ' papf.attribute5 IS NOT NULL ' 
    || ' AND' 
    || ' xcs.carrier_code = papf.attribute5 '
    || ' AND' 
    -- �]�ƈ��敪��'�O��'�ŁA��^���敪���Ώۣ�܂��͢�����o�̓t���O���Ώۣ�̏ꍇ�A�o�͑ΏۊO
    || ' xc2v.complusion_output_code =''' || gc_freight_charge_code_1|| ''''      -- �����o�͋敪
    || ' )' 
    || ' )' 
    || ' )' 
    || ' )' 
    ;
    lb_union := true;
  END IF;
-- 2008/07/09 add S.Takemoto end
--
    lv_sql_tail := lv_sql_tail
    || ' )' 
    || ' ORDER BY' 
    || ' dist_block ASC'              -- �u���b�N
    || ' ,deliver_from ASC'           -- �o�Ɍ�
    || ' ,freight_carrier_code ASC'   -- �^���Ǝ�
    || ' ,schedule_ship_date ASC'     -- �o�ɗ\���
    || ' ,gyoumu_shubetsu_code ASC'   -- �Ɩ����
    || ' ,schedule_arrival_date ASC'  -- ����
    || ' ,delivery_no ASC'            -- �z��No
    || ' ,req_mov_no ASC'             -- �˗�No/�ړ�No
-- 2008/10/27 mod start 1.13 T_TE080_BPO_620�w�E47 �\�[�g���ύX
--    || ' ,item_code ASC' ;            -- ���i�R�[�h
    || ' ,item_code ASC'              -- ���i�R�[�h
--    || ' ,DECODE(item_class_code, ''' || gc_item_cd_prdct     || ''', attribute1 )' -- ������
--    || ' ,DECODE(item_class_code, ''' || gc_item_cd_prdct     || ''', attribute2 )' -- �ŗL�L��
    || ' ,DECODE(''' || gt_param.iv_item_kbn || ''', ''' || gc_item_cd_prdct || ''', attribute1 )' -- ������
    || ' ,DECODE(''' || gt_param.iv_item_kbn || ''', ''' || gc_item_cd_prdct || ''', attribute2 )' -- �ŗL�L��
--    || ' ,DECODE(xic4v.item_class_code, ''' || gc_item_cd_prdct     || ''', ''0'' , TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) )' -- ���b�gNO
    || ' ,DECODE(''' || gt_param.iv_item_kbn || ''', ''' || gc_item_cd_prdct || ''', 0 , TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) )' -- ���b�gNO
    ;
-- 2008/10/27 mod end 1.13 
--
    -- �J�[�\���I�[�v��
    OPEN c_cur FOR  lv_sql_head           || lv_sql_shu_sel_from1 || lv_sql_shu_sel_from2 || 
                    lv_sql_shu_where1     || lv_sql_shu_where2    || lv_sql_sik_sel_from1 || 
                    lv_sql_sik_sel_from2  || lv_sql_sik_where1    || lv_sql_sik_where2    || 
                    lv_sql_ido_sel_from1  || lv_sql_ido_sel_from2 || lv_sql_ido_where1    ||
-- 2008/07/09 add S.Takemoto start
--                    lv_sql_ido_where2     || lv_sql_tail ;
                    lv_sql_ido_where2     || lv_sql_etc_sel_from1 || lv_sql_etc_sel_from2 ||
                    lv_sql_etc_where1     || lv_sql_etc_where2    || lv_sql_tail ;
-- 2008/07/09 add S.Takemoto end
    -- �o���N�t�F�b�`
    FETCH c_cur BULK COLLECT INTO gt_report_data ;
    -- �J�[�\���N���[�Y
    CLOSE c_cur ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
      IF ( c_cur%ISOPEN ) THEN
        CLOSE c_cur;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML��������(F-5)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �O�񃌃R�[�h�i�[�p
    lv_tmp_deliver_from       type_report_data.deliver_from%TYPE ;          -- �o�Ɍ������
    lv_tmp_carrier_code       type_report_data.freight_carrier_code%TYPE ;  -- �^���ƎҖ����
    lv_tmp_ship_date          type_report_data.schedule_ship_date%TYPE ;    -- �o�ɗ\��������
    lv_tmp_gyoumu_shubetsu    type_report_data.gyoumu_shubetsu%TYPE ;       -- �Ɩ���ʖ����
    lv_tmp_delivery_no        type_report_data.delivery_no%TYPE ;           -- �z��No�����
    lv_tmp_request_no         type_report_data.req_mov_no%TYPE ;            -- �˗�No/�ړ�No�����
    lv_tmp_item_code          type_report_data.item_code%TYPE ;             -- �i�ڃR�[�h�����
--
    -- �^�O�o�͔���t���O
    lb_dispflg_ship_info          BOOLEAN := TRUE ;       -- �o�Ɍ������
    lb_dispflg_career_info        BOOLEAN := TRUE ;       -- �^���ƎҖ����
    lb_dispflg_career_plan_info   BOOLEAN := TRUE ;       -- �o�ɗ\��������
    lb_dispflg_bsns_kind_info     BOOLEAN := TRUE ;       -- �Ɩ���ʖ����
    lb_dispflg_delivery_no        BOOLEAN := TRUE ;       -- �z��No�����
    lb_dispflg_irai               BOOLEAN := TRUE ;       -- �˗�No/�ړ�No�����
    lb_dispflg_item_code          BOOLEAN := TRUE ;       -- �i�ڃR�[�h�����
--
    -- ���v����
    lv_sum_quantity_deli          NUMBER ;
    lv_sum_quantity_req           NUMBER ;
    lv_total_quantity             NUMBER ;
--
    -- ���b�Z�[�W
    lv_msg                        VARCHAR2(100);
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : �^�O���ݒ菈��
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2                 -- �^�O��
      ,ivsub_tag_value      IN  VARCHAR2                 -- �f�[�^
      ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- �f�[�^
    )
    IS
      ln_data_index  NUMBER ;    -- XML�f�[�^��ݒ肷��C���f�b�N�X
    BEGIN
      ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
      gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
--
      IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
        -- �^�O�o��
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
      ELSE
        -- �f�[�^�o��
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
        gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
      END IF;
    END prcsub_set_xml_data ;
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2  -- �^�O��
    )
    IS
    BEGIN
      prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
    END prcsub_set_xml_data ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -----------------------------------------------------
    -- �ϐ������ݒ�
    -- -----------------------------------------------------
    gt_xml_data_table.DELETE ;
    lv_tmp_deliver_from       := NULL ;
    lv_tmp_carrier_code       := NULL ;
    lv_tmp_ship_date          := NULL ;
    lv_tmp_gyoumu_shubetsu    := NULL ;
    lv_tmp_delivery_no        := NULL ;
    lv_tmp_request_no         := NULL ;
    lv_tmp_item_code          := NULL ;
    lv_sum_quantity_deli      := 0 ;
    lv_sum_quantity_req       := 0 ;
    lv_total_quantity         := 0 ;
--
    -- -----------------------------------------------------
    -- �w�b�_���ݒ�
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
    prcsub_set_xml_data('lg_ship_info') ;
--
    -- -----------------------------------------------------
    -- ���[0���pXML�f�[�^�쐬
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      lv_msg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
      prcsub_set_xml_data('g_ship_info') ;
      prcsub_set_xml_data('head_title'          , gv_report_title) ;
      prcsub_set_xml_data('chohyo_id'           , gc_report_id) ;
      prcsub_set_xml_data('exec_time'           , TO_CHAR(gd_common_sysdate, gc_date_fmt_all)) ;
    -- MOD START 2008/06/04 NAKADA dep_cd��gv_dept_nm�Adep_nm��gv_user_nm�����蓖�Ă�
      prcsub_set_xml_data('dep_cd'              , gv_dept_nm) ;
      prcsub_set_xml_data('dep_nm'              , gv_user_nm) ;
    -- MOD END   2008/06/04 NAKADA
      prcsub_set_xml_data('shukko_date_from'    , TO_CHAR(gt_param.iv_ship_from
                                                        , gc_date_fmt_ymd_ja)) ;
      prcsub_set_xml_data('shukko_date_to'      , TO_CHAR(gt_param.iv_ship_to
                                                        , gc_date_fmt_ymd_ja)) ;
      prcsub_set_xml_data('lg_career_info') ;
      prcsub_set_xml_data('g_career_info') ;
      prcsub_set_xml_data('lg_career_plan_info') ;
      prcsub_set_xml_data('g_career_plan_info') ;
      prcsub_set_xml_data('lg_bsns_kind_info') ;
      prcsub_set_xml_data('g_bsns_kind_info') ;
      prcsub_set_xml_data('lg_denpyo') ;
      prcsub_set_xml_data('g_denpyo') ;
      prcsub_set_xml_data('msg', lv_msg) ;
      prcsub_set_xml_data('/g_denpyo') ;
      prcsub_set_xml_data('/lg_denpyo') ;
      prcsub_set_xml_data('/g_bsns_kind_info') ;
      prcsub_set_xml_data('/lg_bsns_kind_info') ;
      prcsub_set_xml_data('/g_career_plan_info') ;
      prcsub_set_xml_data('/lg_career_plan_info') ;
      prcsub_set_xml_data('/g_career_info') ;
      prcsub_set_xml_data('/lg_career_info') ;
      prcsub_set_xml_data('/g_ship_info') ;
    END IF ;
--
    -- -----------------------------------------------------
    -- XML�f�[�^�쐬
    -- -----------------------------------------------------
    <<detail_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XML�f�[�^�ݒ�
      -- ====================================================
      -- �o�Ɍ������
      IF ( lb_dispflg_ship_info ) THEN
        prcsub_set_xml_data('g_ship_info') ;
        prcsub_set_xml_data('head_title'          , gv_report_title) ;
        prcsub_set_xml_data('chohyo_id'           , gc_report_id) ;
        prcsub_set_xml_data('exec_time'           , TO_CHAR(gd_common_sysdate, gc_date_fmt_all)) ;
    -- MOD START 2008/06/04 NAKADA dep_cd��gv_dept_nm�Adep_nm��gv_user_nm�����蓖�Ă�
        prcsub_set_xml_data('dep_cd'              , gv_dept_nm) ;
        prcsub_set_xml_data('dep_nm'              , gv_user_nm) ;
    -- MOD END   2008/06/04 NAKADA
        prcsub_set_xml_data('shukko_date_from'    , TO_CHAR(gt_param.iv_ship_from
                                                          , gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('shukko_date_to'      , TO_CHAR(gt_param.iv_ship_to
                                                          , gc_date_fmt_ymd_ja)) ;
        prcsub_set_xml_data('shukko_moto'         , gt_report_data(i).deliver_from) ;
        prcsub_set_xml_data('shukko_moto_nm'      , gt_report_data(i).description) ;
        prcsub_set_xml_data('lg_career_info') ;
      END IF ;
--
      -- �^���ƎҖ����
      IF ( lb_dispflg_career_info ) THEN
        prcsub_set_xml_data('g_career_info') ;
        prcsub_set_xml_data('career_id'             , gt_report_data(i).freight_carrier_code) ;
        prcsub_set_xml_data('career_nm'             , gt_report_data(i).carrier_full_name) ;
        prcsub_set_xml_data('lg_career_plan_info') ;
      END IF ;
--
      -- �o�ɗ\��������
      IF ( lb_dispflg_career_plan_info ) THEN
        prcsub_set_xml_data('g_career_plan_info') ;
        prcsub_set_xml_data('career_date'           , TO_CHAR(gt_report_data(i).schedule_ship_date
                                                            , gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('lg_bsns_kind_info') ;
      END IF ;
--
      -- �Ɩ���ʖ����
      IF ( lb_dispflg_bsns_kind_info ) THEN
        prcsub_set_xml_data('g_bsns_kind_info') ;
        prcsub_set_xml_data('bsns_kind'             , gt_report_data(i).gyoumu_shubetsu) ;
--mod start 1.10.1
--        prcsub_set_xml_data('item_kbn'              , gt_report_data(i).item_class_name) ;
        IF (gt_param.iv_item_kbn IS NOT NULL) THEN
          prcsub_set_xml_data('item_kbn'              , gt_report_data(i).item_class_name) ;
        ELSE
          prcsub_set_xml_data('item_kbn'              , NULL) ;
        END IF;
--mod end 1.10.1
        -- �^��������
        prcsub_set_xml_data('career_order_nm'       , gv_hchu_cat_value) ;
        prcsub_set_xml_data('career_order_adr'      , gv_hchu_address_value) ;
        prcsub_set_xml_data('career_order_tel'      , gv_hchu_tel_value) ;
        -- �^���˗���
        prcsub_set_xml_data('career_request_nm'     , gv_irai_cat_value_full) ;
        prcsub_set_xml_data('career_request_adr'    , gv_irai_address_value) ;
        prcsub_set_xml_data('career_request_tel'    , gv_irai_tel_value) ;
        prcsub_set_xml_data('lg_denpyo') ;
      END IF;
--
      -- �z��No�����
      IF ( lb_dispflg_delivery_no ) THEN
        prcsub_set_xml_data('g_denpyo') ;
        prcsub_set_xml_data('new_modify_flg'        , gt_report_data(i).new_modify_flg) ;
        prcsub_set_xml_data('shukko_date'           
                          , TO_CHAR(gt_report_data(i).schedule_arrival_date
                                  , gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('delivery_no'           , gt_report_data(i).delivery_no) ;
        prcsub_set_xml_data('delivery_kbn'          , gt_report_data(i).shipping_method_code) ;
        prcsub_set_xml_data('delivery_nm'           , gt_report_data(i).ship_method_meaning) ;
--mod start 1.3
--        prcsub_set_xml_data('mixed_weight'          , gt_report_data(i).sum_loading_weight) ;
--        prcsub_set_xml_data('mixed_weight_tani'     , gv_uom_weight) ;
--        prcsub_set_xml_data('mixed_capacity'        , gt_report_data(i).sum_loading_capacity) ;
--        prcsub_set_xml_data('mixed_capacity_tani'   , gv_uom_capacity) ;
        IF (gt_report_data(i).delivery_no IS NOT NULL) THEN
          --�z��No���ݒ肳��Ă���ꍇ
          prcsub_set_xml_data('mixed_weight'          , gt_report_data(i).sum_loading_weight) ;
          prcsub_set_xml_data('mixed_weight_tani'     , gv_uom_weight) ;
          prcsub_set_xml_data('mixed_capacity'        , gt_report_data(i).sum_loading_capacity) ;
          prcsub_set_xml_data('mixed_capacity_tani'   , gv_uom_capacity) ;
        ELSE
          --�z��No���ݒ肳��Ă��Ȃ��ꍇ
          prcsub_set_xml_data('mixed_weight'          , NULL) ;
          prcsub_set_xml_data('mixed_weight_tani'     , NULL) ;
          prcsub_set_xml_data('mixed_capacity'        , NULL) ;
          prcsub_set_xml_data('mixed_capacity_tani'   , NULL) ;
        END IF;
--mod end 1.3
--del start 1.10.3
--        prcsub_set_xml_data('knkt_base_cd'          , gt_report_data(i).head_sales_branch) ;
--        prcsub_set_xml_data('knkt_base_nm'          , gt_report_data(i).party_name) ;
--        prcsub_set_xml_data('delivery_ship'         , gt_report_data(i).deliver_to) ;
--        prcsub_set_xml_data('delivery_ship_nm'      , gt_report_data(i).party_site_full_name) ;
--        prcsub_set_xml_data('delivery_ship_adr'
--                          , gt_report_data(i).address_line1 || gt_report_data(i).address_line2) ;
--        prcsub_set_xml_data('jpr_user_cd'           , gt_report_data(i).jpr_user_code) ;
--        prcsub_set_xml_data('tel_no'                , gt_report_data(i).phone) ;
--del end 1.10.3
        prcsub_set_xml_data('lg_irai') ;
      END IF ;
--
      -- �˗�No/�ړ�No�����
      IF ( lb_dispflg_irai ) THEN
        prcsub_set_xml_data('g_irai') ;
        prcsub_set_xml_data('irai_no'               , gt_report_data(i).req_mov_no) ;
        prcsub_set_xml_data('tehai_no'              , gt_report_data(i).tehai_no) ;
        prcsub_set_xml_data('zen_delivery_no'       , gt_report_data(i).prev_delivery_no) ;
        prcsub_set_xml_data('po_no'                 , gt_report_data(i).po_no) ;
        prcsub_set_xml_data('invoice_no'            , gt_report_data(i).slip_number) ;
        prcsub_set_xml_data('tekiyo'                , gt_report_data(i).shipping_instructions) ;
        prcsub_set_xml_data('sum_weight'            , gt_report_data(i).sum_weightm_capacity) ;
        prcsub_set_xml_data('sum_weight_tani'       , gt_report_data(i).sum_weightm_capacity_t) ;
        prcsub_set_xml_data('time_shitei_from'      , gt_report_data(i).arrival_time_from) ;
        prcsub_set_xml_data('time_shitei_to'        , gt_report_data(i).arrival_time_to) ;
        prcsub_set_xml_data('kosu'                  , gt_report_data(i).small_quantity) ;
        prcsub_set_xml_data('collected_pallet_qty'  , gt_report_data(i).collected_pallet_qty) ;
--add start 1.10.3
        prcsub_set_xml_data('knkt_base_cd'          , gt_report_data(i).head_sales_branch) ;
        prcsub_set_xml_data('knkt_base_nm'          , gt_report_data(i).party_name) ;
        prcsub_set_xml_data('delivery_ship'         , gt_report_data(i).deliver_to) ;
        prcsub_set_xml_data('delivery_ship_nm'      , gt_report_data(i).party_site_full_name) ;
        prcsub_set_xml_data('delivery_ship_adr'
                          , gt_report_data(i).address_line1 || gt_report_data(i).address_line2) ;
        prcsub_set_xml_data('jpr_user_cd'           , gt_report_data(i).jpr_user_code) ;
        prcsub_set_xml_data('tel_no'                , gt_report_data(i).phone) ;
--add end 1.10.3
        prcsub_set_xml_data('lg_dtl_info') ;
      END IF ;
--
      -- �i�ڃR�[�h�����
      prcsub_set_xml_data('g_dtl_info') ;
      prcsub_set_xml_data('item_cd'                 , gt_report_data(i).item_code) ;
      prcsub_set_xml_data('item_nm'                 , gt_report_data(i).item_name) ;
      prcsub_set_xml_data('net'                     , gt_report_data(i).net) ;
      prcsub_set_xml_data('lot_no'                  , gt_report_data(i).lot_no) ;
      prcsub_set_xml_data('lot_date'                , gt_report_data(i).attribute1) ;
      prcsub_set_xml_data('best_bfr_date'           , gt_report_data(i).attribute3) ;
      prcsub_set_xml_data('lot_sign'                , gt_report_data(i).attribute2) ;
      prcsub_set_xml_data('num_qty'                 , gt_report_data(i).num_of_cases) ;
      prcsub_set_xml_data('quantity'                , gt_report_data(i).qty) ;
      prcsub_set_xml_data('quantity_tani'           , gt_report_data(i).conv_unit) ;
      prcsub_set_xml_data('/g_dtl_info') ;
--
      IF ( gt_report_data(i).qty IS NOT NULL ) THEN
        -- �˗�No/�ړ�No�P�ʂ̐��ʍ��v
        lv_sum_quantity_deli  :=  lv_sum_quantity_deli  + gt_report_data(i).qty ;
        -- �z��No�P�ʂ̐��ʍ��v
        lv_sum_quantity_req   :=  lv_sum_quantity_req   + gt_report_data(i).qty ;
        -- �w�b�_�[�P�ʂ̐��ʍ��v
        lv_total_quantity     :=  lv_total_quantity     + gt_report_data(i).qty ;
      END IF ;
--
      -- ====================================================
      -- ���ݏ������̃f�[�^��ێ�
      -- ====================================================
      lv_tmp_deliver_from       := gt_report_data(i).deliver_from ;
      lv_tmp_carrier_code       := gt_report_data(i).freight_carrier_code ;
      lv_tmp_ship_date          := gt_report_data(i).schedule_ship_date ;
      lv_tmp_gyoumu_shubetsu    := gt_report_data(i).gyoumu_shubetsu ;
      lv_tmp_delivery_no        := gt_report_data(i).delivery_no ;
      lv_tmp_request_no         := gt_report_data(i).req_mov_no ;
      lv_tmp_item_code          := gt_report_data(i).item_code ;
--
      -- ====================================================
      -- �o�͔���
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- �˗�No/�ړ�No
        IF ( lv_tmp_request_no = gt_report_data(i + 1).req_mov_no ) THEN
          lb_dispflg_irai               :=  FALSE ;
        ELSE
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- �z��No
-- mod start 1.12
--        IF ( lv_tmp_delivery_no = gt_report_data(i + 1).delivery_no ) THEN
        IF ( lv_tmp_delivery_no = gt_report_data(i + 1).delivery_no ) 
          OR (lv_tmp_delivery_no IS NULL) THEN
-- mod end 1.12
          lb_dispflg_delivery_no        :=  FALSE ;
        ELSE
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- �Ɩ����
        IF ( lv_tmp_gyoumu_shubetsu = gt_report_data(i + 1).gyoumu_shubetsu ) THEN
          lb_dispflg_bsns_kind_info     :=  FALSE ;
        ELSE
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- �o�ɗ\���
        IF ( lv_tmp_ship_date = gt_report_data(i + 1).schedule_ship_date ) THEN
          lb_dispflg_career_plan_info   :=  FALSE ;
        ELSE
          lb_dispflg_career_plan_info   :=  TRUE ;
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- �^���Ǝ�
-- mod start 1.12
--        IF ( lv_tmp_carrier_code = gt_report_data(i + 1).freight_carrier_code ) THEN
        IF ( lv_tmp_carrier_code = gt_report_data(i + 1).freight_carrier_code ) 
          OR (lv_tmp_carrier_code IS NULL) THEN
-- mod end 1.12
          lb_dispflg_career_info        :=  FALSE ;
        ELSE
          lb_dispflg_career_info        :=  TRUE ;
          lb_dispflg_career_plan_info   :=  TRUE ;
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
        -- �o�Ɍ�
        IF ( lv_tmp_deliver_from = gt_report_data(i + 1).deliver_from ) THEN
          lb_dispflg_ship_info          :=  FALSE ;
        ELSE
          lb_dispflg_ship_info          :=  TRUE ;
          lb_dispflg_career_info        :=  TRUE ;
          lb_dispflg_career_plan_info   :=  TRUE ;
          lb_dispflg_bsns_kind_info     :=  TRUE ;
          lb_dispflg_delivery_no        :=  TRUE ;
          lb_dispflg_irai               :=  TRUE ;
        END IF ;
--
      ELSE
        lb_dispflg_ship_info          :=  TRUE ;
        lb_dispflg_career_info        :=  TRUE ;
        lb_dispflg_career_plan_info   :=  TRUE ;
        lb_dispflg_bsns_kind_info     :=  TRUE ;
        lb_dispflg_delivery_no        :=  TRUE ;
        lb_dispflg_irai               :=  TRUE ;
      END IF;
--
      -- ====================================================
      -- �I���^�O�ݒ�
      -- ====================================================
--
      IF (lb_dispflg_irai) THEN
        prcsub_set_xml_data('/lg_dtl_info') ;
--
        -- �z��No�P�ʂ̍��v����
        prcsub_set_xml_data('sum_quantity_req'      , lv_sum_quantity_req) ;
        -- �z��No�P�ʂ̃N���A
        lv_sum_quantity_req   :=  0;
--
        IF ( lb_dispflg_delivery_no ) THEN
          -- �˗�No/�ړ�No�P�ʂ̍��v����
--add start 1.3
          --�z��No�����ݒ�̏ꍇ�͔z��No�P�ʂ̐��ʍ��v�͋󗓂Ƃ���
          IF (gt_report_data(i).delivery_no IS NULL) THEN
            lv_sum_quantity_deli := NULL;
          END IF;
--add end 1.3
          prcsub_set_xml_data('sum_quantity_deli'     , lv_sum_quantity_deli) ;
          -- �˗�No/�ړ�No�P�ʂ̃N���A
          lv_sum_quantity_deli  :=  0;
        END IF ;
--
        IF (lb_dispflg_bsns_kind_info) THEN
          -- �w�b�_�[�P�ʂ̐��ʍ��v
          prcsub_set_xml_data('total_quantity'     , lv_total_quantity) ;
          lv_total_quantity :=  0;
        END IF;
--
        prcsub_set_xml_data('/g_irai') ;
      END IF;
--
      IF (lb_dispflg_delivery_no) THEN
        prcsub_set_xml_data('/lg_irai') ;
        prcsub_set_xml_data('/g_denpyo') ;
      END IF;
--
      IF (lb_dispflg_bsns_kind_info) THEN
        prcsub_set_xml_data('/lg_denpyo') ;
        prcsub_set_xml_data('/g_bsns_kind_info') ;
      END IF;
--
      IF (lb_dispflg_career_plan_info) THEN
        prcsub_set_xml_data('/lg_bsns_kind_info') ;
        prcsub_set_xml_data('/g_career_plan_info') ;
      END IF;
--
      IF (lb_dispflg_career_info) THEN
        prcsub_set_xml_data('/lg_career_plan_info') ;
        prcsub_set_xml_data('/g_career_info') ;
      END IF;
--
      IF (lb_dispflg_ship_info) THEN
        prcsub_set_xml_data('/lg_career_info') ;
        prcsub_set_xml_data('/g_ship_info') ;
      END IF;
    END LOOP detail_data_loop;
--
    -- ====================================================
    -- �I���^�O�ݒ�
    -- ====================================================
    prcsub_set_xml_data('/lg_ship_info') ;
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XML�f�[�^�ϊ�(F-5)
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    iv_name  IN VARCHAR2
   ,iv_value IN VARCHAR2
   ,ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF ;
--
    RETURN(lv_convert_data);
--
  END fnc_convert_into_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT   VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT   VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(32767);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(32767);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_xml_string    VARCHAR2(32000) ;
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ��������(F-1,F-2,F-3)
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- ���[�f�[�^�擾����(F-4)
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML��������(F-5)
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML�o�͏���(F-5)
    -- ==================================================
    -- XML�w�b�_���o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := fnc_convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type
                       ) ;
      -- XML�f�[�^�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_xml_string) ;
    END LOOP xml_loop ;
--
    --XML�f�[�^�폜
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn) AND (gt_report_data.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** ���[0����O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
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
  PROCEDURE main(
     errbuf                     OUT    VARCHAR2         --  �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode                    OUT    VARCHAR2         --  ���^�[���E�R�[�h    --# �Œ� #
    ,iv_dept                    IN     VARCHAR2         --  01 : ����
    ,iv_plan_decide_kbn         IN     VARCHAR2         --  02 : �\��/�m��敪
    ,iv_ship_from               IN     VARCHAR2         --  03 : �o�ɓ�From
    ,iv_ship_to                 IN     VARCHAR2         --  04 : �o�ɓ�To
    ,iv_shukko_haisou_kbn       IN     VARCHAR2         --  05 : �o��/�z���敪
    ,iv_gyoumu_shubetsu         IN     VARCHAR2         --  06 : �Ɩ����
    ,iv_notif_date              IN     VARCHAR2         --  07 : �m��ʒm���{��
    ,iv_notif_time_from         IN     VARCHAR2         --  08 : �m��ʒm���{����From
    ,iv_notif_time_to           IN     VARCHAR2         --  09 : �m��ʒm���{����To
    ,iv_freight_carrier_code    IN     VARCHAR2         --  10 : �^���Ǝ�
    ,iv_block1                  IN     VARCHAR2         --  11 : �u���b�N1
    ,iv_block2                  IN     VARCHAR2         --  12 : �u���b�N2
    ,iv_block3                  IN     VARCHAR2         --  13 : �u���b�N3
    ,iv_shipped_locat_code      IN     VARCHAR2         --  14 : �o�Ɍ�
    ,iv_mov_num                 IN     VARCHAR2         --  15 : �˗�No/�ړ�No
    ,iv_shime_date              IN     VARCHAR2         --  16 : ���ߎ��{��
    ,iv_shime_time_from         IN     VARCHAR2         --  17 : ���ߎ��{����From
    ,iv_shime_time_to           IN     VARCHAR2         --  18 : ���ߎ��{����To
    ,iv_online_kbn              IN     VARCHAR2         --  19 : �I�����C���Ώۋ敪
    ,iv_item_kbn                IN     VARCHAR2         --  20 : �i�ڋ敪
    ,iv_shukko_keitai           IN     VARCHAR2         --  21 : �o�Ɍ`��
    ,iv_unsou_irai_inzi_kbn     IN     VARCHAR2         --  22 : �^���˗����󎚋敪
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(32767);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(32767);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    -- ���̓p�����[�^���O���[�o���ϐ��ɕێ�
    gt_param.iv_dept                    := iv_dept ;                  --  01 : ����
    gt_param.iv_plan_decide_kbn         := iv_plan_decide_kbn ;       --  02 : �\��/�m��敪
    --  03 : �o�ɓ�From
    gt_param.iv_ship_from               := FND_DATE.CANONICAL_TO_DATE(iv_ship_from) ;
    --  04 : �o�ɓ�To
    gt_param.iv_ship_to                 := FND_DATE.CANONICAL_TO_DATE(iv_ship_to) ;
    gt_param.iv_shukko_haisou_kbn       := iv_shukko_haisou_kbn ;     --  05 : �o��/�z���敪
    gt_param.iv_gyoumu_shubetsu         := iv_gyoumu_shubetsu ;       --  06 : �Ɩ����
    --  07 : �m��ʒm���{��
    gt_param.iv_notif_date              := FND_DATE.CANONICAL_TO_DATE(iv_notif_date) ;
    gt_param.iv_notif_time_from         := iv_notif_time_from ;       --  08 : �m��ʒm���{����From
    gt_param.iv_notif_time_to           := iv_notif_time_to ;         --  09 : �m��ʒm���{����To
    gt_param.iv_freight_carrier_code    := iv_freight_carrier_code ;  --  10 : �^���Ǝ�
    gt_param.iv_block1                  := iv_block1 ;                --  11 : �u���b�N1
    gt_param.iv_block2                  := iv_block2 ;                --  12 : �u���b�N2
    gt_param.iv_block3                  := iv_block3 ;                --  13 : �u���b�N3
    gt_param.iv_shipped_locat_code      := iv_shipped_locat_code ;    --  14 : �o�Ɍ�
    gt_param.iv_mov_num                 := iv_mov_num ;               --  15 : �˗�No/�ړ�No
    --  16 : ���ߎ��{��
    gt_param.iv_shime_date              := FND_DATE.CANONICAL_TO_DATE(iv_shime_date) ;
    gt_param.iv_shime_time_from         := iv_shime_time_from ;       --  17 : ���ߎ��{����From
    gt_param.iv_shime_time_to           := iv_shime_time_to ;         --  18 : ���ߎ��{����To
    gt_param.iv_online_kbn              := iv_online_kbn ;            --  19 : �I�����C���Ώۋ敪
    gt_param.iv_item_kbn                := iv_item_kbn ;              --  20 : �i�ڋ敪
    gt_param.iv_shukko_keitai           := iv_shukko_keitai ;         --  21 : �o�Ɍ`��
    gt_param.iv_unsou_irai_inzi_kbn     := iv_unsou_irai_inzi_kbn ;   --  22 : �^���˗����󎚋敪
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh620002c;
/
