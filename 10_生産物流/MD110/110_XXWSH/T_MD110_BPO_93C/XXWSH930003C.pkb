CREATE OR REPLACE PACKAGE BODY xxwsh930003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930003C(body)
 * Description      : ���o�ɏ�񍷈ك��X�g�i�o�Ɋ�j
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD050_BPO_930)
 *                    ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD070_BPO_93C)
 * Version          : 1.14
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_out_data         PROCEDURE : �w�l�k�f�[�^�o�͏���
 *  prc_ins_temp_data           PROCEDURE : ���ԃe�[�u���o�^
 *  prc_set_temp_data           PROCEDURE : ���ԃe�[�u���o�^�f�[�^�ݒ�
 *  prc_create_ship_data        PROCEDURE : �o�ׁE�x���f�[�^���o����
 *  prc_create_move_data        PROCEDURE : �ړ��f�[�^���o����
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[���
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/19    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/06/23    1.1   Oohashi  Takao   �s����O�Ή�
 *  2008/06/25    1.2   Oohashi  Takao   �s����O�Ή�
 *  2008/06/30    1.3   Oohashi  Takao   �s����O�Ή�
 *  2008/07/02    1.4   Kawano   Yuko    ST�s��Ή�#352
 *  2008/07/07    1.5   Akiyoshi Shiina  �ύX�v���Ή�#92
 *  2008/07/08    1.5   Satoshi  Yunba   �֑������Ή�
 *  2008/07/24    1.6   Akiyoshi Shiina  ST�s�#197�A�����ۑ�#32�A�����ύX�v��#180�Ή�
 *  2008/10/10    1.7   Naoki    Fukuda  �����e�X�g��Q#338�Ή�
 *  2008/10/17    1.8   Naoki    Fukuda  �����e�X�g��Q#146�Ή�
 *  2008/10/17    1.8   Naoki    Fukuda  �ۑ�T_S_458�Ή�(������C�ӓ��̓p�����[�^�ɕύX�BPACKAGE�̏C���͂Ȃ�)
 *  2008/10/17    1.8   Naoki    Fukuda  �ύX�v��#210�Ή�
 *  2008/10/20    1.9   Naoki    Fukuda  �ۑ�T_S_486�Ή�
 *  2008/10/20    1.9   Naoki    Fukuda  �����e�X�g��Q#394(1)�Ή�
 *  2008/10/20    1.9   Naoki    Fukuda  �����e�X�g��Q#394(2)�Ή�
 *  2008/10/31    1.10  Naoki    Fukuda  �����w�E#461�Ή�
 *  2008/11/13    1.11  Naoki    Fukuda  �����w�E#603�Ή�
 *  2008/11/17    1.12  Naoki    Fukuda  �����w�E#651�Ή�(�ۑ�T_S_486�đΉ�)
 *  2008/12/03    1.13  Naoki    Fukuda  �{�ԏ�Q#333�Ή�
 *  2008/12/06    1.14  Miyata           �{�ԏ�Q#516�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================================================================================
  -- ���[�U�[�錾��
  -- ===============================================================================================
  -- ==================================================
  -- �O���[�o���萔
  -- ==================================================
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXWSH930003C' ;     -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXWSH930003T' ;     -- ���[ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V����
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- �f�[�^�O�����b�Z�[�W
--
  ------------------------------
  -- �Q�ƃ^�C�v
  ------------------------------
  -- �o�׋Ɩ����
  gc_lookup_biz_type          CONSTANT VARCHAR2(100) := 'XXWSH_SHIPPING_BIZ_TYPE' ;
  -- ���o�ɏ�񍷈ك��X�g�o�͋敪
  gc_lookup_output_type       CONSTANT VARCHAR2(100) := 'XXWSH_930CD_LIST_OUTPUT_CLASS' ;
  -- �o�׎x���敪
  gc_lookup_ship_prov_class   CONSTANT VARCHAR2(100) := 'XXWSH_SHIPPING_SHIKYU_CLASS' ;
  -- �z���敪
  gc_lookup_ship_method_code  CONSTANT VARCHAR2(100) := 'XXCMN_SHIP_METHOD' ;
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_lookup_doc_type          CONSTANT VARCHAR2(100) := 'XXINV_DOCUMENT_TYPE' ;
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_lookup_rec_type          CONSTANT VARCHAR2(100) := 'XXINV_RECORD_TYPE' ;
  -- ���b�g�X�e�[�^�X
  gc_lookup_lot_status        CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS' ;
--
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �i�ڋ敪
  gc_item_div_gen         CONSTANT VARCHAR2(1)  := '1' ;  -- ����
  gc_item_div_shi         CONSTANT VARCHAR2(1)  := '2' ;  -- ����
  gc_item_div_han         CONSTANT VARCHAR2(1)  := '4' ;  -- �����i
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- ���i
  -- �o�׋Ɩ����
  gc_business_type_s      CONSTANT VARCHAR2(1)  := '1' ;  -- �o��
  gc_business_type_p      CONSTANT VARCHAR2(1)  := '2' ;  -- �x��
  gc_business_type_m      CONSTANT VARCHAR2(1)  := '3' ;  -- �ړ�
  -- ���o�ɏ�񍷈ك��X�g�o�͋敪
  gc_output_type_nrep     CONSTANT VARCHAR2(1)  := '1' ;  -- ����
  gc_output_type_rsrv     CONSTANT VARCHAR2(1)  := '2' ;  -- �ۗ�
  gc_output_type_diff     CONSTANT VARCHAR2(1)  := '3' ;  -- �˗���
  gc_output_type_ndif     CONSTANT VARCHAR2(1)  := '4' ;  -- ���ٖ�
  gc_output_type_ndel     CONSTANT VARCHAR2(1)  := '5' ;  -- �o�ɖ�
  gc_output_type_nstc     CONSTANT VARCHAR2(1)  := '6' ;  -- ���ɖ�
  gc_output_type_iodf     CONSTANT VARCHAR2(1)  := '7' ;  -- �o����
  -- ���َ��R
  gc_reason_nrep          CONSTANT VARCHAR2(10) := '����' ;
  gc_reason_rsrv          CONSTANT VARCHAR2(10) := '�ۗ�' ;
  gc_reason_diff          CONSTANT VARCHAR2(10) := '�˗���' ;
  gc_reason_ndif          CONSTANT VARCHAR2(10) := '���ٖ�' ;
  gc_reason_ndel          CONSTANT VARCHAR2(10) := '�o�ɖ�' ;
  gc_reason_nstc          CONSTANT VARCHAR2(10) := '���ɖ�' ;
  gc_reason_iodf          CONSTANT VARCHAR2(10) := '�o����' ;
  -- �X�e�[�^�X
  gc_req_status_s_inp     CONSTANT VARCHAR2(2)  := '01' ;   -- ���͒�
  gc_req_status_s_cmpa    CONSTANT VARCHAR2(2)  := '02' ;   -- ���_�m��
  gc_req_status_s_cmpb    CONSTANT VARCHAR2(2)  := '03' ;   -- ���ߍς�
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '04' ;   -- �o�׎��ьv���
  gc_req_status_p_inp     CONSTANT VARCHAR2(2)  := '05' ;   -- ���͒�
  gc_req_status_p_cmpa    CONSTANT VARCHAR2(2)  := '06' ;   -- ���͊���
  gc_req_status_p_cmpb    CONSTANT VARCHAR2(2)  := '07' ;   -- ��̍�
  gc_req_status_p_cmpc    CONSTANT VARCHAR2(2)  := '08' ;   -- �o�׎��ьv���
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99' ;   -- ���
  -- �ړ��^�C�v
  gc_mov_type_y           CONSTANT VARCHAR2(1)  := '1' ;    -- �ϑ�����
  gc_mov_type_n           CONSTANT VARCHAR2(1)  := '2' ;    -- �ϑ��Ȃ�
  -- �ړ��X�e�[�^�X
  gc_mov_status_req       CONSTANT VARCHAR2(2)  := '01' ;   -- �˗���
  gc_mov_status_cmp       CONSTANT VARCHAR2(2)  := '02' ;   -- �˗���
  gc_mov_status_adj       CONSTANT VARCHAR2(2)  := '03' ;   -- ������
  gc_mov_status_del       CONSTANT VARCHAR2(2)  := '04' ;   -- �o�ɕ񍐗L
  gc_mov_status_stc       CONSTANT VARCHAR2(2)  := '05' ;   -- ���ɕ񍐗L
  gc_mov_status_dsr       CONSTANT VARCHAR2(2)  := '06' ;   -- ���o�ɕ񍐗L
  gc_mov_status_ccl       CONSTANT VARCHAR2(2)  := '99' ;   -- ���
  -- EOS�f�[�^�^�C�v
  gc_eos_type_req_ship_k  CONSTANT VARCHAR2(3)  := '110' ;  -- ���_�E�z����o�׈˗�
  gc_eos_type_req_move_o  CONSTANT VARCHAR2(3)  := '120' ;  -- �ړ��o�Ɉ˗�
  gc_eos_type_req_move_i  CONSTANT VARCHAR2(3)  := '130' ;  -- �ړ����Ɉ˗�
  gc_eos_type_req_dliv_k  CONSTANT VARCHAR2(3)  := '140' ;  -- ���_�E�z����z���˗�
  gc_eos_type_req_dliv_o  CONSTANT VARCHAR2(3)  := '150' ;  -- �ړ��o�ɔz���˗�
  gc_eos_type_rpt_ship_y  CONSTANT VARCHAR2(3)  := '200' ;  -- �L���o�ו�
  gc_eos_type_rpt_ship_k  CONSTANT VARCHAR2(3)  := '210' ;  -- ���_�o�׊m���
  gc_eos_type_rpt_ship_n  CONSTANT VARCHAR2(3)  := '215' ;  -- ���o�׊m���
  gc_eos_type_rpt_move_o  CONSTANT VARCHAR2(3)  := '220' ;  -- �ړ��o�Ɋm���
  gc_eos_type_rpt_move_i  CONSTANT VARCHAR2(3)  := '230' ;  -- �ړ����Ɋm���
  gc_eos_type_claim_fare  CONSTANT VARCHAR2(3)  := '300' ;  -- �^������
  gc_eos_type_rpt_invent  CONSTANT VARCHAR2(3)  := '400' ;  -- �I���m���
  gc_eos_type_mnt_master  CONSTANT VARCHAR2(3)  := '900' ;  -- �}�X�^�����e�i���X
  -- YesNo�敪
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- �o�׎x���敪
  gc_sp_class_ship        CONSTANT VARCHAR2(1)  := '1' ;    -- �o�׈˗�
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- �x���˗�
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- �ړ��i�v���O����������j
  -- �o�׎x���敪�i�ϊ��j
  gc_sp_class_name_ship   CONSTANT VARCHAR2(4)  := '�o��' ; -- �o�׈˗�
  gc_sp_class_name_prov   CONSTANT VARCHAR2(4)  := '�x��' ; -- �x���˗�
  gc_sp_class_name_move   CONSTANT VARCHAR2(4)  := '�ړ�' ; -- �ړ��i�v���O����������j
  -- �󒍃J�e�S��
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER' ;
  -- ���b�g�Ǘ��敪
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
  -- �o�׈˗��h�e�F�ۗ��X�e�[�^�X
  gc_reserved_status_y    CONSTANT VARCHAR2(1) := '1' ;     -- �ۗ�
  -- ���ԃe�[�u���F�w�����ы敪
  gc_inst_rslt_div_h      CONSTANT VARCHAR2(1) := '0' ;     -- �ۗ�  2008/10/10 �����e�X�g��Q#394(1) Add
  gc_inst_rslt_div_i      CONSTANT VARCHAR2(1) := '1' ;     -- �w��
  gc_inst_rslt_div_r      CONSTANT VARCHAR2(1) := '2' ;     -- ����
--
  ------------------------------
  -- ���̑�
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      business_type     VARCHAR2(1)         -- 01 : �Ɩ����
     ,prod_div          VARCHAR2(1)         -- 02 : ���i�敪
     ,item_div          VARCHAR2(1)         -- 03 : �i�ڋ敪
     ,date_from         DATE                -- 04 : �o�ɓ�From
     ,date_to           DATE                -- 05 : �o�ɓ�To
     ,dept_code         VARCHAR2(4)         -- 06 : ����
     ,output_type       VARCHAR2(1)         -- 07 : �o�͋敪
     ,deliver_type_id   NUMBER              -- 08 : �o�Ɍ`��
     ,block_01          VARCHAR2(2)         -- 09 : �u���b�N�P
     ,block_02          VARCHAR2(2)         -- 10 : �u���b�N�Q
     ,block_03          VARCHAR2(2)         -- 11 : �u���b�N�R
     ,deliver_from      VARCHAR2(4)         -- 12 : �o�Ɍ�
     ,online_type       VARCHAR2(1)         -- 13 : �I�����C���Ώۋ敪
     ,request_no        VARCHAR2(12)        -- 14 : �˗�No�^�ړ�No
    ) ;
  -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
  TYPE rec_temp_tab_data IS RECORD 
    (
      location_code     xxwsh_930c_tmp.location_code%TYPE       -- �o�ɑq�ɃR�[�h
     ,location_name     xxwsh_930c_tmp.location_name%TYPE       -- �o�ɑq�ɖ���
     ,ship_date         xxwsh_930c_tmp.ship_date%TYPE           -- �o�ɓ�
     ,arvl_date         xxwsh_930c_tmp.arvl_date%TYPE           -- ���ɓ�
     ,head_sales_code   xxwsh_930c_tmp.head_sales_code%TYPE     -- �Ǌ����_�R�[�h
     ,head_sales_name   xxwsh_930c_tmp.head_sales_name%TYPE     -- �Ǌ����_����
     ,deliver_code      xxwsh_930c_tmp.deliver_code%TYPE        -- �z���斔�͓��ɐ�R�[�h
     ,deliver_name      xxwsh_930c_tmp.deliver_name%TYPE        -- �z���斔�͓��ɐ於��
     ,career_code       xxwsh_930c_tmp.career_code%TYPE         -- �^���Ǝ҃R�[�h
     ,career_name       xxwsh_930c_tmp.career_name%TYPE         -- �^���ƎҖ���
     ,ship_method_code  xxwsh_930c_tmp.ship_method_code%TYPE    -- �z���敪�R�[�h
     ,ship_method_name  xxwsh_930c_tmp.ship_method_name%TYPE    -- �z���敪����
     ,ship_type         xxwsh_930c_tmp.ship_type%TYPE           -- �Ɩ����
     ,delivery_no       xxwsh_930c_tmp.delivery_no%TYPE         -- �z���m��
     ,request_no        xxwsh_930c_tmp.request_no%TYPE          -- �˗��m���^�ړ��m��
     ,item_code         xxwsh_930c_tmp.item_code%TYPE           -- �i�ڃR�[�h
     ,item_name         xxwsh_930c_tmp.item_name%TYPE           -- �i�ږ���
     ,lot_no            xxwsh_930c_tmp.lot_no%TYPE              -- ���b�g�ԍ�
     ,product_date      xxwsh_930c_tmp.product_date%TYPE        -- ������
     ,use_by_date       xxwsh_930c_tmp.use_by_date%TYPE         -- �ܖ�����
     ,original_char     xxwsh_930c_tmp.original_char%TYPE       -- �ŗL�L��
     ,lot_status        xxwsh_930c_tmp.lot_status%TYPE          -- �i��
     ,quant_r           xxwsh_930c_tmp.quant_r%TYPE             -- �˗���
     ,quant_i           xxwsh_930c_tmp.quant_i%TYPE             -- ���ɐ�
     ,quant_o           xxwsh_930c_tmp.quant_o%TYPE             -- �o�ɐ�
     ,reason            xxwsh_930c_tmp.reason%TYPE              -- ���َ��R
     ,inst_rslt_div     xxwsh_930c_tmp.inst_rslt_div%TYPE       -- �w�����ы敪�i1�F�w�� 2�F���сj
    ) ;
--
  -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_get_data IS RECORD 
    (
      location_code    VARCHAR2(100)  -- �o�ɑq�ɃR�[�h
     ,location_name    VARCHAR2(100)  -- �o�ɑq�ɖ���
     ,ship_date        DATE     -- �o�ɓ�
     ,arvl_date        DATE     -- ���ɓ�
-- mod start ver1.1
--     ,po_no            VARCHAR2(100)  -- ���������F�Ǌ����_
     ,head_sales_branch VARCHAR2(100)  -- ���������F�Ǌ����_
-- mod end ver1.1
     ,deliver_id       VARCHAR2(100)  -- ���������F�z����
     ,career_id        VARCHAR2(100)  -- ���������F�^���Ǝ�
     ,ship_method_code VARCHAR2(100)  -- ���������F�z���敪
     ,order_type       VARCHAR2(100)  -- �Ɩ���ʁi�R�[�h�j
     ,delivery_no      VARCHAR2(100)  -- �z���m��
     ,request_no       VARCHAR2(100)  -- �˗��m��
     ,order_line_id    VARCHAR2(100)  -- ���������F���ׂh�c
     ,item_id          VARCHAR2(100)  -- ���������F�i�ڂh�c
     ,item_code        VARCHAR2(100)  -- �i�ڃR�[�h
     ,item_name        VARCHAR2(100)  -- �i�ږ���
     ,lot_ctl          VARCHAR2(100)  -- ���������F���b�g�g�p
     ,quant_r          NUMBER   -- �˗����i���b�g�Ǘ��O�j
     ,quant_i          NUMBER   -- ���ɐ��i���b�g�Ǘ��O�j
     ,quant_o          NUMBER   -- �o�ɐ��i���b�g�Ǘ��O�j
-- 2008/07/24 A.Shiina v1.7 ADD Start
     ,quant_d          NUMBER   -- ���󐔗�(�C���^�t�F�[�X�p)
-- 2008/07/24 A.Shiina v1.7 ADD End
     ,status           VARCHAR2(100)  -- �󒍃w�b�_�X�e�[�^�X
-- add start ver1.1
     ,conv_unit        VARCHAR2(240)  -- ���o�Ɋ��Z�P��
     ,num_of_cases     NUMBER         -- �P�[�X����
-- add end ver1.1
-- add start ver1.2
     ,lot_id           NUMBER         -- ���b�gID
-- add end ver1.2
-- add start ver1.3
     ,prod_class_code  VARCHAR(100)    -- ���i�敪
-- add end ver1.3
-- 2008/07/07 A.Shiina v1.5 Update Start
     ,freight_charge_code   VARCHAR(1)  -- �^���敪
     ,complusion_output_kbn VARCHAR(1)  -- �����o�͋敪
-- 2008/07/07 A.Shiina v1.5 Update End
-- 2008/11/17 �����w�E#651 Add Start -----------------------------------------------
     ,no_instr_actual  VARCHAR(1)        -- �w���Ȃ����сF'Y' �w���������:'N'
     ,lot_inst_cnt     NUMBER            -- �w�����b�g�̌���
     ,row_num          NUMBER            -- �˗�No�E�i�ڂ��ƂɃ��b�gID������1����̔�
-- 2008/11/17 �����w�E#651 Add End -------------------------------------------------
    ) ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;      -- �p�����[�^
  gn_data_cnt           NUMBER := 0 ;         -- �����f�[�^�J�E���^
--
  gb_get_flg            BOOLEAN := FALSE ;    -- �f�[�^�擾����t���O
  gt_xml_data_table     XML_DATA ;            -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER  := 0 ;        -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  gn_created_by               NUMBER ;  -- �쐬��
  gn_last_updated_by          NUMBER ;  -- �ŏI�X�V��
  gn_last_update_login        NUMBER ;  -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER ;  -- �v��ID
  gn_program_application_id   NUMBER ;  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gn_program_id               NUMBER ;  -- �R���J�����g�E�v���O����ID
--
  gv_nvl_null_char        VARCHAR2(4) := 'NULL';   -- 2008/10/31 �����w�E#461 Add
  gn_nvl_null_num         NUMBER := 0;             -- 2008/10/31 �����w�E#461 Add
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ���[�U�[���^�O�o��
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
--
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ) ;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
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
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_out_data
   * Description      : �w�l�k�f�[�^�o�͏���
   ************************************************************************************************/
  PROCEDURE prc_create_out_data
    (
      ov_errbuf     OUT    VARCHAR2             -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT    VARCHAR2             -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT    VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_out_data' ; -- �v���O������
--
    lv_sql_dtl        CONSTANT VARCHAR2(32000)
      := ' SELECT DISTINCT'
      || '        x9t.item_code         AS item_code'
      || '       ,x9t.item_name         AS item_name'
      || '       ,x9t.lot_no            AS lot_no'
      || '       ,TO_CHAR( x9t.product_date, ''YYYY/MM/DD'' ) AS product_date'
      || '       ,TO_CHAR( x9t.use_by_date , ''YYYY/MM/DD'' ) AS use_by_date'
      || '       ,x9t.original_char     AS original_char'
      || '       ,x9t.lot_status        AS lot_status'
      || '       ,NVL( x9t.quant_r, ''0'' ) AS quant_r'
      || '       ,NVL( x9t.quant_i, ''0'' ) AS quant_i'
      || '       ,NVL( x9t.quant_o, ''0'' ) AS quant_o'
      || '       ,x9t.reason                AS reason'
      || ' FROM xxwsh_930c_tmp   x9t'
      || ' WHERE NVL( x9t.reason, ''*'' ) = NVL( :V1, NVL( x9t.reason, ''*'' ) )'
-- mod start ver1.1
--      || ' AND   x9t.delivery_no = :V2'
      || ' AND   NVL(x9t.delivery_no,''X'') = NVL(:V2,''X'')'
-- mod end ver1.1
      || ' AND   x9t.request_no  = :V3'
      || ' AND   x9t.inst_rslt_div = :V4'    -- 2008/10/20 �����e�X�g��Q#394(1) Add
      ;
    lv_sql_order_1    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_CHAR( x9t.product_date, ''YYYY/MM/DD'' )'
      || '         ,x9t.original_char'
      ;
    lv_sql_order_2    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_NUMBER( x9t.lot_no )'
      ;
    -- ==================================================
    -- �J  �[  �\  ��  ��  ��
    -- ==================================================
    -- �}�X�^���R�[�h�擾�J�[�\��
    CURSOR cu_mst( p_ship_type xxwsh_930c_tmp.ship_type%TYPE  )
    IS
      SELECT mst.location_code
            ,mst.location_name
            ,mst.ship_date
            ,mst.arvl_date
            ,mst.head_sales_code
            ,mst.head_sales_name
            ,mst.deliver_code
            ,mst.deliver_name
            ,mst.career_code
            ,mst.career_name
            ,mst.ship_method_code
            ,mst.ship_method_name
            ,mst.ship_type
            ,mst.delivery_no
            ,mst.request_no
            ,mst.inst_rslt_div   -- 2008/10/20 �����e�X�g��Q#394(1) Add
      FROM
      (
        SELECT DISTINCT
               x9t.location_code     AS location_code
              ,x9t.location_name     AS location_name
              ,TO_CHAR( x9t.ship_date , 'YYYY/MM/DD' ) AS ship_date
              ,TO_CHAR( x9t.arvl_date , 'YYYY/MM/DD' ) AS arvl_date
              ,x9t.head_sales_code   AS head_sales_code
              ,x9t.head_sales_name   AS head_sales_name
              ,x9t.deliver_code      AS deliver_code
              ,x9t.deliver_name      AS deliver_name
              ,x9t.career_code       AS career_code
              ,x9t.career_name       AS career_name
              ,x9t.ship_method_code  AS ship_method_code
              ,x9t.ship_method_name  AS ship_method_name
              ,x9t.ship_type         AS ship_type
              ,x9t.delivery_no       AS delivery_no
              ,x9t.request_no        AS request_no
              ,x9t.inst_rslt_div     AS inst_rslt_div
        FROM xxwsh_930c_tmp   x9t
        WHERE x9t.ship_type = NVL( p_ship_type, x9t.ship_type )
      ) mst
      ORDER BY mst.location_code
              ,mst.ship_date
              ,mst.arvl_date
              ,mst.delivery_no
              ,mst.request_no
              ,mst.inst_rslt_div
    ;
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lv_sql                  VARCHAR2(32000) ;
    -- �u���C�N���f�p
    lv_tmp_location_code    VARCHAR2(4)  := '*' ; 
    -- �}�X�^���ڏo�͗p
    lv_ship_date            VARCHAR2(10) ;        -- �o�ɓ�
    lv_arvl_date            VARCHAR2(10) ;        -- ���ɓ�
    lv_head_sales_code      VARCHAR2(4) ;         -- �Ǌ����_�R�[�h
    lv_head_sales_name      VARCHAR2(20) ;        -- �Ǌ����_����
    lv_deliver_code         VARCHAR2(9) ;         -- �z���斔�͓��ɐ�R�[�h
    lv_deliver_name         VARCHAR2(60) ;        -- �z���斔�͓��ɐ於��
    lv_career_code          VARCHAR2(4) ;         -- �^���Ǝ҃R�[�h
    lv_career_name          VARCHAR2(20) ;        -- �^���ƎҖ���
    lv_ship_method_code     VARCHAR2(2) ;         -- �z���敪�R�[�h
    lv_ship_method_name     VARCHAR2(14) ;        -- �z���敪����
    lv_ship_type            VARCHAR2(4) ;         -- �Ɩ����
    lv_delivery_no          VARCHAR2(12) ;        -- �z���m��
    lv_request_no           VARCHAR2(12) ;        -- �˗��m���^�ړ��m��
    lv_param_ship_type      VARCHAR2(4) ;         -- �Ɩ���ʁi�r�p�k���s�p�j
    lv_param_reason         VARCHAR2(6) ;         -- ���َ��R�i�r�p�k���s�p�j
-- add start ver1.2
    lv_item_code            VARCHAR2(7) ;         -- �i�ڃR�[�h
    lv_item_name            VARCHAR2(20) ;        -- �i�ږ���
-- add end ver1.2
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;             -- REF_CURSOR�p
    TYPE ret_value  IS RECORD 
      (
        item_code           VARCHAR2(7)         -- �i�ڃR�[�h
       ,item_name           VARCHAR2(20)        -- �i�ږ���
       ,lot_no              VARCHAR2(10)        -- ���b�g�ԍ�
       ,product_date        VARCHAR2(10)        -- ������
       ,use_by_date         VARCHAR2(10)        -- �ܖ�����
       ,original_char       VARCHAR2(6)         -- �ŗL�L��
       ,lot_status          VARCHAR2(10)        -- �i��
       ,quant_r             VARCHAR2(12)        -- �˗���
       ,quant_i             VARCHAR2(12)        -- ���ɐ�
       ,quant_o             VARCHAR2(12)        -- �o�ɐ�
       ,reason              VARCHAR2(6)         -- ���َ��R
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���ԃe�[�u���f�[�^���o�r�p�k������
    -- ====================================================
    ------------------------------
    -- �o�D�i�ڋ敪�����i�̏ꍇ
    ------------------------------
    IF ( gr_param.item_div = gc_item_div_sei ) THEN
      lv_sql := lv_sql_dtl || lv_sql_order_1 ;
--
    ------------------------------
    -- �o�D�i�ڋ敪�����i�ȊO�̏ꍇ
    ------------------------------
    ELSE
      lv_sql := lv_sql_dtl || lv_sql_order_2 ;
--
    END IF ;
--
    -- ====================================================
    -- �p�����[�^�ϊ�
    -- ====================================================
    BEGIN
      IF ( gr_param.business_type IS NOT NULL ) THEN
        SELECT xlvv.meaning
        INTO   lv_param_ship_type
        FROM xxcmn_lookup_values_v xlvv
        WHERE xlvv.lookup_type = gc_lookup_biz_type
        AND   xlvv.lookup_code = gr_param.business_type
        ;
      END IF ;
      IF ( gr_param.output_type IS NOT NULL ) THEN
        SELECT xlvv.meaning
        INTO   lv_param_reason
        FROM xxcmn_lookup_values_v xlvv
        WHERE xlvv.lookup_type = gc_lookup_output_type
        AND   xlvv.lookup_code = gr_param.output_type
        ;
      END IF ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_others_expt ;
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_others_expt ;
    END ;
--
    -- ====================================================
    -- ���X�g�O���[�v�J�n�^�O�i�o�ɑq�Ɂj
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lctn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<mst_data_loop>>
    FOR re_data IN cu_mst( lv_param_ship_type ) LOOP
      -- ----------------------------------------------------
      -- ���׃J�[�\���I�[�v��
      -- ----------------------------------------------------
      OPEN lc_ref FOR lv_sql
      USING lv_param_reason
           ,re_data.delivery_no
           ,re_data.request_no
           ,re_data.inst_rslt_div   -- 2008/10/20 �����e�X�g��Q#394(1) Add
      ;
      FETCH lc_ref INTO lr_ref ;
--
      IF ( lc_ref%FOUND ) THEN
        -- ====================================================
        -- �o�ɑq�Ƀu���C�N
        -- ====================================================
        IF ( re_data.location_code <> lv_tmp_location_code ) THEN
          -- ----------------------------------------------------
          -- �O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          -- ���񃌃R�[�h�̏ꍇ�͕\�����Ȃ�
          IF ( lv_tmp_location_code <> '*' ) THEN
            -- ���X�g�O���[�v�I���^�O�i�o�׏��j
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- �O���[�v�I���^�O�i�o�ɑq�Ɂj
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lctn' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
--
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lctn' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �f�[�^�^�O�o��
          -- ----------------------------------------------------
          -- �o�ɑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.location_code ;
          -- �o�ɑq�ɖ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.location_name ;
--
          -- ----------------------------------------------------
          -- ���X�g�O���[�v�J�n�^�O�i�o�ׁj
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_spmt_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �u���C�N���f�p���ڂ̑ޔ�
          -- ----------------------------------------------------
          lv_tmp_location_code := re_data.location_code ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_spmt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �}�X�^���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_ship_date        := re_data.ship_date ;           -- �o�ɓ�
        lv_arvl_date        := re_data.arvl_date ;           -- ���ɓ�
        lv_head_sales_code  := re_data.head_sales_code ;     -- �Ǌ����_�R�[�h
        lv_head_sales_name  := re_data.head_sales_name ;     -- �Ǌ����_����
        lv_deliver_code     := re_data.deliver_code ;        -- �z���斔�͓��ɐ�R�[�h
        lv_deliver_name     := re_data.deliver_name ;        -- �z���斔�͓��ɐ於��
        lv_career_code      := re_data.career_code ;         -- �^���Ǝ҃R�[�h
        lv_career_name      := re_data.career_name ;         -- �^���ƎҖ���
        lv_ship_method_code := re_data.ship_method_code ;    -- �z���敪�R�[�h
        lv_ship_method_name := re_data.ship_method_name ;    -- �z���敪����
        lv_ship_type        := re_data.ship_type ;           -- �Ɩ����
        lv_delivery_no      := re_data.delivery_no ;         -- �z���m��
        lv_request_no       := re_data.request_no ;          -- �˗��m���^�ړ��m��
--
        -- ====================================================
        -- ���׏��o��
        -- ====================================================
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i���ׁj
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        <<dtl_data_loop>>
        LOOP
--
          gn_data_cnt := gn_data_cnt + 1 ;
--
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�i���ׁj
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �f�[�^�^�O�o��
          -- ----------------------------------------------------
          -- �o�ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_date ;
          -- ���ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'arvl_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_arvl_date ;
          -- �Ǌ����_�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_head_sales_code ;
          -- �Ǌ����_����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_head_sales_name ;
          -- �z����E���ɐ�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_deliver_code ;
          -- �z����E���ɐ於��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_deliver_name ;
          -- �^���Ǝ҃R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'career_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_career_code ;
          -- �^���ƎҖ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'career_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_career_name ;
          -- �z���敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_method_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_code ;
          -- �z���敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_method_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_name ;
          -- �Ɩ����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_type ;
          -- �z���m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_delivery_no ;
          -- �˗��E�ړ��m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_request_no ;
--
          -- �i�ڃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.2
--          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
          IF ( lv_item_code = lr_ref.item_code AND lv_request_no IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          ELSIF ( lv_item_code IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
          ELSE
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
          END IF;
-- mod start ver1.2
          -- �i�ږ���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.2
--          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
          IF ( lv_item_name = lr_ref.item_name AND lv_request_no IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          ELSIF ( lv_item_name IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
          ELSE
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
          END IF;
-- mod start ver1.2
          -- ���b�g�m��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_no ;
          -- ������
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.product_date ;
          -- �ܖ�����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.use_by_date ;
          -- �ŗL�L��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.original_char ;
          -- �i��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_status' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_status ;
          -- �˗���
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_r' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_r ;
          -- ���ɐ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_i' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_i ;
          -- �o�ɐ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_o' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_o ;
          -- ���َ��R
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.reason ;
--
          -- ----------------------------------------------------
          -- �O���[�v�I���^�O�i���ׁj
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �}�X�^���ڂ̏�����
          -- ----------------------------------------------------
          lv_ship_date        := NULL ;
          lv_arvl_date        := NULL ;
          lv_head_sales_code  := NULL ;
          lv_head_sales_name  := NULL ;
          lv_deliver_code     := NULL ;
          lv_deliver_name     := NULL ;
          lv_career_code      := NULL ;
          lv_career_name      := NULL ;
          lv_ship_method_code := NULL ;
          lv_ship_method_name := NULL ;
          lv_ship_type        := NULL ;
          lv_delivery_no      := NULL ;
          lv_request_no       := NULL ;
--
-- add start ver1.2
          lv_item_code := lr_ref.item_code ;
          lv_item_name := lr_ref.item_name ;
-- add end ver1.2
          FETCH lc_ref INTO lr_ref ;
          EXIT WHEN lc_ref%NOTFOUND ;
--
        END LOOP dtl_data_loop ;
--
        -- ====================================================
        -- �J�[�\���N���[�Y
        -- ====================================================
        CLOSE lc_ref ;
--
        -- ���X�g�O���[�v�I���^�O�i���ׁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_spmt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      ELSE
        -- ====================================================
        -- �J�[�\���N���[�Y
        -- ====================================================
        CLOSE lc_ref ;
--
      END IF ;
--
    END LOOP mst_data_loop ;
--
    -- ====================================================
    -- �O���[�v�I���^�O�o��
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O�i�o�׏��j
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �O���[�v�I���^�O�i�o�ɑq�Ɂj
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lctn' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- ���X�g�O���[�v�I���^�O�i�o�ɑq�Ɂj
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lctn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_out_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_data
   * Description      : ���ԃe�[�u���o�^
   ************************************************************************************************/
  PROCEDURE prc_ins_temp_data
    (
      ir_temp_tab   IN     rec_temp_tab_data    -- ���ԃe�[�u���o�^�f�[�^
     ,ov_errbuf     OUT    VARCHAR2             -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT    VARCHAR2             -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT    VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_ins_temp_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- ���ԃe�[�u���o�^
    -- ====================================================
    INSERT INTO xxwsh_930c_tmp
      (
        location_code                 -- �o�ɑq�ɃR�[�h
       ,location_name                 -- �o�ɑq�ɖ���
       ,ship_date                     -- �o�ɓ�
       ,arvl_date                     -- ���ɓ�
       ,head_sales_code               -- �Ǌ����_�R�[�h
       ,head_sales_name               -- �Ǌ����_����
       ,deliver_code                  -- �z���斔�͓��ɐ�R�[�h
       ,deliver_name                  -- �z���斔�͓��ɐ於��
       ,career_code                   -- �^���Ǝ҃R�[�h
       ,career_name                   -- �^���ƎҖ���
       ,ship_method_code              -- �z���敪�R�[�h
       ,ship_method_name              -- �z���敪����
       ,ship_type                     -- �Ɩ����
       ,delivery_no                   -- �z���m��
       ,request_no                    -- �˗��m���^�ړ��m��
       ,item_code                     -- �i�ڃR�[�h
       ,item_name                     -- �i�ږ���
       ,lot_no                        -- ���b�g�ԍ�
       ,product_date                  -- ������
       ,use_by_date                   -- �ܖ�����
       ,original_char                 -- �ŗL�L��
       ,lot_status                    -- �i��
       ,quant_r                       -- �˗���
       ,quant_i                       -- ���ɐ�
       ,quant_o                       -- �o�ɐ�
       ,reason                        -- ���َ��R
       ,inst_rslt_div                 -- �w�����ы敪
       ,created_by                    -- �쐬��
       ,creation_date                 -- �쐬��
       ,last_updated_by               -- �ŏI�X�V��
       ,last_update_date              -- �ŏI�X�V��
       ,last_update_login             -- �ŏI�X�V���O�C��
       ,request_id                    -- �v��ID
       ,program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                    -- �R���J�����g�E�v���O����ID
       ,program_update_date           -- �v���O�����X�V��
      )
    VALUES
      (
        SUBSTRB( ir_temp_tab.location_code   , 1, 4  )  -- �o�ɑq�ɃR�[�h
       ,SUBSTRB( ir_temp_tab.location_name   , 1, 20 )  -- �o�ɑq�ɖ���
       ,ir_temp_tab.ship_date                           -- �o�ɓ�
       ,ir_temp_tab.arvl_date                           -- ���ɓ�
       ,SUBSTRB( ir_temp_tab.head_sales_code , 1, 4  )  -- �Ǌ����_�R�[�h
       ,SUBSTRB( ir_temp_tab.head_sales_name , 1, 20 )  -- �Ǌ����_����
       ,SUBSTRB( ir_temp_tab.deliver_code    , 1, 9  )  -- �z���斔�͓��ɐ�R�[�h
       ,SUBSTRB( ir_temp_tab.deliver_name    , 1, 60 )  -- �z���斔�͓��ɐ於��
       ,SUBSTRB( ir_temp_tab.career_code     , 1, 4  )  -- �^���Ǝ҃R�[�h
       ,SUBSTRB( ir_temp_tab.career_name     , 1, 20 )  -- �^���ƎҖ���
       ,SUBSTRB( ir_temp_tab.ship_method_code, 1, 2  )  -- �z���敪�R�[�h
       ,SUBSTRB( ir_temp_tab.ship_method_name, 1, 14 )  -- �z���敪����
       ,SUBSTRB( ir_temp_tab.ship_type       , 1, 4  )  -- �Ɩ����
       ,SUBSTRB( ir_temp_tab.delivery_no     , 1, 12 )  -- �z���m��
       ,SUBSTRB( ir_temp_tab.request_no      , 1, 12 )  -- �˗��m���^�ړ��m��
       ,SUBSTRB( ir_temp_tab.item_code       , 1, 7  )  -- �i�ڃR�[�h
       ,SUBSTRB( ir_temp_tab.item_name       , 1, 20 )  -- �i�ږ���
       ,SUBSTRB( ir_temp_tab.lot_no          , 1, 10 )  -- ���b�g�ԍ�
       ,ir_temp_tab.product_date                        -- ������
       ,ir_temp_tab.use_by_date                         -- �ܖ�����
       ,SUBSTRB( ir_temp_tab.original_char   , 1, 6  )  -- �ŗL�L��
       ,SUBSTRB( ir_temp_tab.lot_status      , 1, 10 )  -- �i��
       ,SUBSTRB( ir_temp_tab.quant_r         , 1, 12 )  -- �˗���
       ,SUBSTRB( ir_temp_tab.quant_i         , 1, 12 )  -- ���ɐ�
       ,SUBSTRB( ir_temp_tab.quant_o         , 1, 12 )  -- �o�ɐ�
       ,SUBSTRB( ir_temp_tab.reason          , 1, 6  )  -- ���َ��R
       ,SUBSTRB( ir_temp_tab.inst_rslt_div   , 1, 1  )  -- �w�����ы敪
       ,gn_created_by               -- �쐬��
       ,SYSDATE                     -- �쐬��
       ,gn_last_updated_by          -- �ŏI�X�V��
       ,SYSDATE                     -- �ŏI�X�V��
       ,gn_last_update_login        -- �ŏI�X�V���O�C��
       ,gn_request_id               -- �v��ID
       ,gn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,gn_program_id               -- �R���J�����g�E�v���O����ID
       ,SYSDATE                     -- �v���O�����X�V��
      ) ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
   * Procedure Name   : prc_set_temp_data
   * Description      : ���ԃe�[�u���o�^�f�[�^�ݒ�
   ************************************************************************************************/
  PROCEDURE prc_set_temp_data
    (
      ir_get_data   IN    rec_get_data        -- ���o�f�[�^
     ,or_temp_tab   OUT   rec_temp_tab_data   -- ���ԃe�[�u���o�^�f�[�^
     ,ov_errbuf     OUT   VARCHAR2            -- �G���[�E���b�Z�[�W
     ,ov_retcode    OUT   VARCHAR2            -- ���^�[���E�R�[�h
     ,ov_errmsg     OUT   VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'prc_set_temp_data' ; -- �v���O������
-- 2008/07/24 A.Shiina v1.7 ADD Start
    cv_eos_data_cd_200  CONSTANT VARCHAR2(3) := '200';  -- 200 �L���o�ו�
    cv_eos_data_cd_210  CONSTANT VARCHAR2(3) := '210';  -- 210 ���_�o�׊m���
    cv_eos_data_cd_215  CONSTANT VARCHAR2(3) := '215';  -- 215 ���o�׊m���
    cv_eos_data_cd_220  CONSTANT VARCHAR2(3) := '220';  -- 220 �ړ��o�Ɋm���
    cv_eos_data_cd_230  CONSTANT VARCHAR2(3) := '230';  -- 230 �ړ����Ɋm���
-- 2008/07/24 A.Shiina v1.7 ADD End
--
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')); -- 2008/12/03 �{�ԏ�Q#333 Add
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')); -- 2008/12/03 �{�ԏ�Q#333 Add
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lv_reserved_status  xxwsh_shipping_lines_if.reserved_status%TYPE ;            -- �ۗ��X�e�[�^�X
-- 2008/07/24 A.Shiina v1.7 ADD Start
    lv_eos_data_type    xxwsh_shipping_headers_if.eos_data_type%TYPE ;  -- EOS�f�[�^���
    ln_quant_kbn        NUMBER;         -- ���ʋ敪
--
    ln_cnt              NUMBER := 0 ;   -- ���݃J�E���g
-- 2008/07/24 A.Shiina v1.7 ADD End
--
    ln_temp_cnt         NUMBER := 0 ;   -- �擾���R�[�h�J�E���g
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
--
    --------------------------------------------------
    -- �o�ɑq�ɐݒ�
    --------------------------------------------------
    or_temp_tab.location_code := ir_get_data.location_code ;  -- �o�ɑq�ɃR�[�h
    or_temp_tab.location_name := ir_get_data.location_name ;  -- �o�ɑq�ɖ���
--
    --------------------------------------------------
    -- �o�ɓ��E���ɓ��ݒ�
    --------------------------------------------------
    or_temp_tab.ship_date := ir_get_data.ship_date ;  -- �o�ɓ�
    or_temp_tab.arvl_date := ir_get_data.arvl_date ;  -- ���ɓ�
--
    --------------------------------------------------
    -- �Ǌ����_�ݒ�
    --------------------------------------------------
-- mod start ver1.1
--    IF ( ir_get_data.po_no IS NULL ) THEN
    IF ( ir_get_data.head_sales_branch IS NULL ) THEN
-- mod end ver1.1
      or_temp_tab.head_sales_code := NULL ;
      or_temp_tab.head_sales_name := NULL ;
    ELSE
      BEGIN
        -- Del start ver1.1 -------------------------------
        --SELECT xps.base_code
        --      ,xp.party_short_name
        --INTO   or_temp_tab.head_sales_code    -- �Ǌ����_�R�[�h
        --      ,or_temp_tab.head_sales_name    -- �Ǌ����_����
        --FROM xxcmn_party_sites2_v   xps   -- �p�[�e�B�T�C�g���VIEW2
        ---   ,xxcmn_parties2_v       xp    -- �p�[�e�B���VIEW2
        --WHERE gr_param.date_from BETWEEN xp.start_date_active  AND xp.end_date_active
        --AND   xps.party_id       = xp.party_id
        --AND   gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
        --AND   xps.base_code      = ir_get_data.po_no
        --AND   xps.base_code      = ir_get_data.head_sales_branch
        --;
        -- Del start ver1.1 -------------------------------
--
        -- 2008/12/03 �{�ԏ�Q#333 Del Start ------------------------------------------------
        -- Add start ver1.1 -------------------------------
        --SELECT xca.party_number
        --      ,xca.party_short_name
        --INTO   or_temp_tab.head_sales_code    -- �Ǌ����_�R�[�h
        --      ,or_temp_tab.head_sales_name    -- �Ǌ����_����
        --FROM xxcmn_cust_accounts2_v   xca     -- �ڋq���VIEW2
        --WHERE gr_param.date_from BETWEEN xca.start_date_active  AND xca.end_date_active
        --AND   xca.party_number = ir_get_data.head_sales_branch
        --;
        -- Add End ver1.1 ---------------------------------
        -- 2008/12/03 �{�ԏ�Q#333 Del End -------------------------------------------------
--
        -- 2008/12/03 �{�ԏ�Q#333 Add Start -----------------------------------------------
        SELECT hca.account_number
              ,CASE hca.customer_class_code
                 WHEN '10' THEN xp.party_name
                 ELSE xp.party_short_name
               END
        INTO   or_temp_tab.head_sales_code    -- �Ǌ����_�R�[�h
              ,or_temp_tab.head_sales_name    -- �Ǌ����_����
        FROM   hz_cust_accounts  hca
              ,xxcmn_parties     xp
        WHERE  hca.party_id = xp.party_id
        AND    hca.account_number = ir_get_data.head_sales_branch
        AND    gr_param.date_from BETWEEN xp.start_date_active AND xp.end_date_active
        AND    ROWNUM = 1
        ;
        -- 2008/12/03 �{�ԏ�Q#333 Add End -------------------------------------------------
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          or_temp_tab.head_sales_code := NULL ;
          or_temp_tab.head_sales_name := NULL ;
      END ;
    END IF ;
--
    --------------------------------------------------
    -- �z����ݒ�
    --------------------------------------------------
    BEGIN
      -- �ۗ��f�[�^�̏ꍇ
      IF ( ir_get_data.status IS NULL ) THEN
--        SELECT xps.party_site_number
--              ,xps.party_site_full_name
--        INTO   or_temp_tab.deliver_code   -- �z���斔�͓��ɐ�R�[�h
--              ,or_temp_tab.deliver_name   -- �z���斔�͓��ɐ於��
--        FROM xxcmn_party_sites2_v   xps   -- �p�[�e�B�T�C�g���VIEW2
--        WHERE gr_param.date_from    BETWEEN xps.start_date_active AND xps.end_date_active
--        AND   xps.party_site_number = ir_get_data.deliver_id
--        ;
-- add start ver1.1
        -- �o�׈˗��̏ꍇ
        IF ( ir_get_data.order_type = gc_eos_type_rpt_ship_k ) THEN
--
          -- 2008/12/03 �{�ԏ�Q#333 Del Start ----------------------------------------------
          --SELECT xcas.party_site_number
          --      --,xcas.party_site_short_name  -- 2008/07/02 Del Y.Kawano
          --      ,xcas.party_site_full_name     -- 2008/07/02 Add Y.Kawano
          --INTO   or_temp_tab.deliver_code      -- �z���斔�͓��ɐ�R�[�h
          --      ,or_temp_tab.deliver_name      -- �z���斔�͓��ɐ於��
          --FROM xxcmn_cust_acct_sites2_v   xcas -- �ڋq�T�C�g���VIEW2
          --WHERE gr_param.date_from BETWEEN xcas.start_date_active AND xcas.end_date_active
          ----AND   xcas.cust_acct_site_id  = ir_get_data.deliver_id  -- 2008/07/02 Del Y.Kawano
          --AND   xcas.party_site_id  = ir_get_data.deliver_id        -- 2008/07/02 Add Y.Kawano
          --;
          -- 2008/12/03 �{�ԏ�Q#333 Del End -------------------------------------------------
--
          -- 2008/12/03 �{�ԏ�Q#333 Add Start -----------------------------------------------
          SELECT hzl.province
                ,xps.party_site_name
          INTO   or_temp_tab.deliver_code      -- �z���斔�͓��ɐ�R�[�h
                ,or_temp_tab.deliver_name      -- �z���斔�͓��ɐ於��
          FROM   hz_locations      hzl
                ,xxcmn_party_sites xps
          WHERE  xps.party_site_id = ir_get_data.deliver_id
          AND    xps.location_id = hzl.location_id
          AND    gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 �{�ԏ�Q#333 Add End ----------------------------------
--
        -- �x���˗��̏ꍇ
        ELSIF ( ir_get_data.order_type = gc_eos_type_rpt_ship_y ) THEN
          SELECT xvs.vendor_site_code
                ,xvs.vendor_site_name
          INTO   or_temp_tab.deliver_code   -- �z���斔�͓��ɐ�R�[�h
                ,or_temp_tab.deliver_name   -- �z���斔�͓��ɐ於��
          FROM xxcmn_vendor_sites2_v  xvs   -- �d����T�C�g���VIEW2
          WHERE gr_param.date_from BETWEEN xvs.start_date_active AND xvs.end_date_active
          AND   xvs.vendor_site_id = ir_get_data.deliver_id
          ;
        -- �ړ��˗��̏ꍇ
        ELSIF ( ir_get_data.order_type IN( gc_eos_type_rpt_move_o
                                          ,gc_eos_type_rpt_move_i ) ) THEN
--
          -- 2008/12/03 �{�ԏ�Q#333 Del Start --------------------------------
          --SELECT xil.segment1
          --      ,xil.description
          --INTO   or_temp_tab.deliver_code     -- �z���斔�͓��ɐ�R�[�h
          --      ,or_temp_tab.deliver_name     -- �z���斔�͓��ɐ於��
          --FROM xxcmn_item_locations2_v    xil -- �n�o�l�ۊǏꏊ�}�X�^
          --WHERE xil.inventory_location_id = ir_get_data.deliver_id
          --AND   gr_param.date_from BETWEEN xil.date_from                             -- add ver1.2
          --                         AND     NVL(xil.date_to, gr_param.date_from )     -- add ver1.2
          --;
          -- 2008/12/03 �{�ԏ�Q#333 Del End ----------------------------------
--
          -- 2008/12/03 �{�ԏ�Q#333 Add Start --------------------------------
          SELECT mil.segment1
                ,mil.description
          INTO   or_temp_tab.deliver_code     -- �z���斔�͓��ɐ�R�[�h
                ,or_temp_tab.deliver_name     -- �z���斔�͓��ɐ於��
          FROM   mtl_item_locations mil
          WHERE  mil.inventory_location_id = ir_get_data.deliver_id
          AND    gr_param.date_from BETWEEN NVL(mil.start_date_active,gr_param.date_from)
                                      AND NVL(mil.end_date_active,gr_param.date_from)
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 �{�ԏ�Q#333 Add End ----------------------------------
--
        END IF ;
-- add end ver1.1
      -- �ۗ��f�[�^�ȊO�̏ꍇ
      ELSE
        -- �o�׈˗��̏ꍇ
        IF ( ir_get_data.order_type = gc_sp_class_ship ) THEN
--
          -- Del start ver1.1 -------------------------------
          --SELECT xps.party_site_number
          --      ,xps.party_site_full_name
          --INTO   or_temp_tab.deliver_code   -- �z���斔�͓��ɐ�R�[�h
          --      ,or_temp_tab.deliver_name   -- �z���斔�͓��ɐ於��
          --FROM xxcmn_party_sites2_v   xps   -- �p�[�e�B�T�C�g���VIEW2
          --WHERE gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
          --AND   xps.party_site_id  = ir_get_data.deliver_id
          --;
          -- Del End ver1.1 -------------------------------
--
          -- 2008/12/03 �{�ԏ�Q#333 Del Start ----------------------------------------------
          -- Add start ver1.1 -------------------------------
          --SELECT xcas.party_site_number
          --      --,xcas.party_site_short_name  -- 2008/07/02 Del Y.Kawano
          --      ,xcas.party_site_full_name     -- 2008/07/02 Add Y.Kawano
          --INTO   or_temp_tab.deliver_code      -- �z���斔�͓��ɐ�R�[�h
          --      ,or_temp_tab.deliver_name      -- �z���斔�͓��ɐ於��
          --FROM xxcmn_cust_acct_sites2_v   xcas -- �ڋq�T�C�g���VIEW2
          --WHERE gr_param.date_from BETWEEN xcas.start_date_active AND xcas.end_date_active
          ----AND   xcas.cust_acct_site_id  = ir_get_data.deliver_id --2008/07/02 Del Y.Kawano
          --AND   xcas.party_site_id  = ir_get_data.deliver_id       --2008/07/02 Add Y.Kawano
          --;
          -- Add End ver1.1 -------------------------------
          -- 2008/12/03 �{�ԏ�Q#333 Del End ------------------------------------------------
--
          -- 2008/12/03 �{�ԏ�Q#333 Add Start -----------------------------------------------
          SELECT hzl.province
                ,xps.party_site_name
          INTO   or_temp_tab.deliver_code      -- �z���斔�͓��ɐ�R�[�h
                ,or_temp_tab.deliver_name      -- �z���斔�͓��ɐ於��
          FROM   hz_locations      hzl
                ,xxcmn_party_sites xps
          WHERE  xps.party_site_id = ir_get_data.deliver_id
          AND    xps.location_id = hzl.location_id
          AND    gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 �{�ԏ�Q#333 Add End -------------------------------------------------
--
        -- �x���˗��̏ꍇ
        ELSIF ( ir_get_data.order_type = gc_sp_class_prov ) THEN
          SELECT xvs.vendor_site_code
                ,xvs.vendor_site_name
          INTO   or_temp_tab.deliver_code   -- �z���斔�͓��ɐ�R�[�h
                ,or_temp_tab.deliver_name   -- �z���斔�͓��ɐ於��
          FROM xxcmn_vendor_sites2_v  xvs   -- �d����T�C�g���VIEW2
          WHERE gr_param.date_from BETWEEN xvs.start_date_active AND xvs.end_date_active
          AND   xvs.vendor_site_id = ir_get_data.deliver_id
          ;
        -- �ړ��˗��̏ꍇ
        ELSIF ( ir_get_data.order_type = gc_sp_class_move ) THEN
--
          -- 2008/12/03 �{�ԏ�Q#333 Del Start --------------------------------
          --SELECT xil.segment1
          --      ,xil.description
          --INTO   or_temp_tab.deliver_code     -- �z���斔�͓��ɐ�R�[�h
          --      ,or_temp_tab.deliver_name     -- �z���斔�͓��ɐ於��
          --FROM xxcmn_item_locations2_v    xil -- �n�o�l�ۊǏꏊ�}�X�^
          --WHERE xil.inventory_location_id = ir_get_data.deliver_id
          --AND   gr_param.date_from BETWEEN xil.date_from                            -- add ver1.2
          --                         AND     NVL(xil.date_to, gr_param.date_from )    -- add ver1.2
          --;
          -- 2008/12/03 �{�ԏ�Q#333 Del End ----------------------------------
--
          -- 2008/12/03 �{�ԏ�Q#333 Add Start --------------------------------
          SELECT mil.segment1
                ,mil.description
          INTO   or_temp_tab.deliver_code     -- �z���斔�͓��ɐ�R�[�h
                ,or_temp_tab.deliver_name     -- �z���斔�͓��ɐ於��
          FROM   mtl_item_locations mil
          WHERE  mil.inventory_location_id = ir_get_data.deliver_id
          AND    gr_param.date_from BETWEEN NVL(mil.start_date_active,gr_param.date_from)
                                       AND NVL(mil.end_date_active,gr_param.date_from)
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 �{�ԏ�Q#333 Add End ----------------------------------
--
        END IF ;
--
      END IF ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.deliver_code := NULL ;
        or_temp_tab.deliver_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.deliver_code := NULL ;
        or_temp_tab.deliver_name := NULL ;
    END ;
--
-- 2008/07/07 A.Shiina v1.5 Update Start
   IF  ((ir_get_data.freight_charge_code  = '1')
    OR (ir_get_data.complusion_output_kbn = '1')) THEN
-- 2008/07/07 A.Shiina v1.5 Update End
    --------------------------------------------------
    -- �^���ƎҐݒ�
    --------------------------------------------------
    BEGIN
      -- �ۗ��f�[�^�̏ꍇ
      IF ( ir_get_data.status IS NULL ) THEN
--
        -- 2008/12/03 �{�ԏ�Q#333 Del Start --------------------------------
        --SELECT xc.party_number
        --      ,xc.party_short_name
        --INTO   or_temp_tab.career_code  -- �^���Ǝ҃R�[�h
        --      ,or_temp_tab.career_name  -- �^���ƎҖ���
        --FROM xxcmn_carriers2_v  xc    -- �^���Ǝҏ��VIEW2
        --WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
        ----AND   xc.party_number     = ir_get_data.career_id   -- del ver1.1
        ----AND   xc.party_id         = ir_get_data.career_id     -- add ver1.1    -- 2008/07/07 A.Shiina v1.5 Del
        --AND   xc.party_number     = ir_get_data.career_id                        -- 2008/07/07 A.Shiina v1.5 Add
        --;
        -- 2008/12/03 �{�ԏ�Q#333 Del End ----------------------------------
--
        -- 2008/12/03 �{�ԏ�Q#333 Add Start --------------------------------
        SELECT wc.freight_code
              ,xp.party_short_name
        INTO   or_temp_tab.career_code  -- �^���Ǝ҃R�[�h
              ,or_temp_tab.career_name  -- �^���ƎҖ���
        FROM   wsh_carriers    wc
              ,xxcmn_parties   xp
-- 2008/12/07 T.Miyata Modify Start �{�ԏ�Q#516 ���[�U�����͂���̂�No�̕��Ȃ̂ŁA����������No�Ƃ���B
        --WHERE  wc.carrier_id = ir_get_data.career_id
        WHERE  wc.freight_code = ir_get_data.career_id
-- 2008/12/07 T.Miyata Modify End   �{�ԏ�Q#516
        AND    xp.party_id = wc.carrier_id
        AND    gr_param.date_from BETWEEN xp.start_date_active AND xp.end_date_active
        AND    ROWNUM = 1
        ;
        -- 2008/12/03 �{�ԏ�Q#333 Add End ----------------------------------
--
      -- �ۗ��f�[�^�ȊO�̏ꍇ
      ELSE
--
        -- 2008/12/03 �{�ԏ�Q#333 Del Start --------------------------------
        --SELECT xc.party_number
        --      ,xc.party_short_name
        --INTO   or_temp_tab.career_code  -- �^���Ǝ҃R�[�h
        --      ,or_temp_tab.career_name  -- �^���ƎҖ���
        --FROM xxcmn_carriers2_v  xc    -- �^���Ǝҏ��VIEW2
        --WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
        --AND   xc.party_id        = ir_get_data.career_id
        --;
        -- 2008/12/03 �{�ԏ�Q#333 Del End ----------------------------------
--
        -- 2008/12/03 �{�ԏ�Q#333 Add Start --------------------------------
        SELECT wc.freight_code
              ,xp.party_short_name
        INTO   or_temp_tab.career_code  -- �^���Ǝ҃R�[�h
              ,or_temp_tab.career_name  -- �^���ƎҖ���
        FROM   wsh_carriers    wc
              ,xxcmn_parties   xp
        WHERE  wc.carrier_id = ir_get_data.career_id
        AND    xp.party_id = wc.carrier_id
        AND    gr_param.date_from BETWEEN xp.start_date_active AND xp.end_date_active
        AND    ROWNUM = 1
        ;
        -- 2008/12/03 �{�ԏ�Q#333 Add End ----------------------------------
--
      END IF ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
    END ;
--
-- 2008/07/07 A.Shiina v1.5 Update Start
   END IF;
-- 2008/07/07 A.Shiina v1.5 Update End
    --------------------------------------------------
    -- �z���敪�ݒ�
    --------------------------------------------------
    BEGIN
      SELECT xlv.lookup_code
            ,xlv.meaning
      INTO   or_temp_tab.ship_method_code   -- �z���敪�R�[�h
            ,or_temp_tab.ship_method_name   -- �z���敪����
      FROM xxcmn_lookup_values_v   xlv   -- �N�C�b�N�R�[�h���VIEW
      WHERE xlv.lookup_type = gc_lookup_ship_method_code
      AND   xlv.lookup_code = ir_get_data.ship_method_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.ship_method_code := NULL ;
        or_temp_tab.ship_method_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.ship_method_code := NULL ;
        or_temp_tab.ship_method_name := NULL ;
    END ;
--
    --------------------------------------------------
    -- �Ɩ���ʐݒ�
    --------------------------------------------------
    -- �ۗ��f�[�^�̏ꍇ
    IF ( ir_get_data.status IS NULL ) THEN
--
      -- �o�׈˗��̏ꍇ
      IF ( ir_get_data.order_type = gc_eos_type_rpt_ship_k ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_ship ;  -- �o��
--
      -- �x���˗��̏ꍇ
      ELSIF ( ir_get_data.order_type = gc_eos_type_rpt_ship_y ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_prov ;  -- �x��
--
      -- �ړ��f�[�^�̏ꍇ
      ELSIF ( ir_get_data.order_type IN( gc_eos_type_rpt_move_o
                                        ,gc_eos_type_rpt_move_i ) ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_move ;  -- �ړ�
--
      END IF ;
--
    -- �ۗ��f�[�^�ȊO�̏ꍇ
    ELSE
--
      -- �o�׈˗��̏ꍇ
      IF ( ir_get_data.order_type = gc_sp_class_ship ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_ship ;  -- �o��
--
      -- �x���˗��̏ꍇ
      ELSIF ( ir_get_data.order_type = gc_sp_class_prov ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_prov ;  -- �x��
--
      -- �ړ��f�[�^�̏ꍇ
      ELSIF ( ir_get_data.order_type = gc_sp_class_move ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_move ;  -- �ړ�
--
      END IF ;
--
    END IF ;
--
    --------------------------------------------------
    -- �z���m���E�˗��m���ݒ�
    --------------------------------------------------
    or_temp_tab.delivery_no := ir_get_data.delivery_no ;  -- �z���m��
    or_temp_tab.request_no  := ir_get_data.request_no ;   -- �˗��m���^�ړ��m��
--
    --------------------------------------------------
    -- �i�ڐݒ�
    --------------------------------------------------
    or_temp_tab.item_code := ir_get_data.item_code ;  -- �i�ڃR�[�h
    or_temp_tab.item_name := ir_get_data.item_name ;  -- �i�ږ���
--
    --------------------------------------------------
    -- �w���E���ы敪�ݒ�
    --------------------------------------------------
    -- �ۗ��f�[�^�̏ꍇ
    IF ( ir_get_data.status IS NULL ) THEN
--
      --or_temp_tab.inst_rslt_div := gc_inst_rslt_div_i ; -- �w��  2008/10/10 �����e�X�g��Q#394(1) Del
      or_temp_tab.inst_rslt_div := gc_inst_rslt_div_h ; -- �ۗ�    2008/10/10 �����e�X�g��Q#394(1) Add
--
    -- �ۗ��f�[�^�ȊO�̏ꍇ
    ELSE
--
      -- �o�ׁE�x���̏ꍇ
      IF ( ir_get_data.order_type = gc_sp_class_ship ) THEN
        -- �w�����R�[�h�ł��邩���m�F����
        SELECT COUNT( xoha.order_header_id )
        INTO   ln_temp_cnt
        FROM   xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
        WHERE xoha.career_id             = ir_get_data.career_id
        AND   xoha.shipping_method_code  = ir_get_data.ship_method_code
        AND   xoha.deliver_to_id         = ir_get_data.deliver_id
        AND   xoha.schedule_ship_date    = ir_get_data.ship_date
        AND   xoha.schedule_arrival_date = ir_get_data.arvl_date
        AND   xoha.latest_external_flag  = gc_yn_div_y             -- �ŐV
        AND   xoha.request_no            = ir_get_data.request_no  -- �˗��m��
        ;
      -- �x���̏ꍇ
      ELSIF ( ir_get_data.order_type = gc_sp_class_prov ) THEN
        -- �w�����R�[�h�ł��邩���m�F����
        SELECT COUNT( xoha.order_header_id )
        INTO   ln_temp_cnt
        FROM   xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
        WHERE xoha.career_id             = ir_get_data.career_id
        AND   xoha.shipping_method_code  = ir_get_data.ship_method_code
        AND   xoha.vendor_site_id        = ir_get_data.deliver_id
        AND   xoha.schedule_ship_date    = ir_get_data.ship_date
        AND   xoha.schedule_arrival_date = ir_get_data.arvl_date
        AND   xoha.latest_external_flag  = gc_yn_div_y             -- �ŐV
        AND   xoha.request_no            = ir_get_data.request_no  -- �˗��m��
        ;
      -- �ړ��̏ꍇ
      ELSIF ( ir_get_data.order_type = gc_sp_class_move ) THEN
        -- �w�����R�[�h�ł��邩���m�F����
        SELECT COUNT( xmrih.mov_hdr_id )
        INTO   ln_temp_cnt
        FROM   xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
        WHERE xmrih.career_id             = ir_get_data.career_id
        AND   xmrih.shipping_method_code  = ir_get_data.ship_method_code
        AND   xmrih.schedule_ship_date    = ir_get_data.ship_date
        AND   xmrih.schedule_arrival_date = ir_get_data.arvl_date
        AND   xmrih.mov_num               = or_temp_tab.request_no  -- �ړ��m��
        ;
      END IF ;

      -- �w�����R�[�h�̏ꍇ
      IF ln_temp_cnt > 0 THEN
        or_temp_tab.inst_rslt_div := gc_inst_rslt_div_i ; -- �w��
--
      -- �w�����R�[�h�ł͂Ȃ��ꍇ
      ELSE
        or_temp_tab.inst_rslt_div := gc_inst_rslt_div_r ; -- ����
      END IF ;
--
    END IF ;
--
    --------------------------------------------------
    -- ���b�g���ݒ�
    --------------------------------------------------
-- del satart ver1.1
    -- ���b�g�Ǘ��i�ȊO�̏ꍇ
--    IF ( ir_get_data.lot_ctl = gc_lot_ctl_n ) THEN
--
--      or_temp_tab.lot_no        := NULL ;   -- ���b�g�ԍ�
--      or_temp_tab.product_date  := NULL ;   -- ������
--      or_temp_tab.use_by_date   := NULL ;   -- �ܖ�����
--      or_temp_tab.original_char := NULL ;   -- �ŗL�L��
--      or_temp_tab.lot_status    := NULL ;   -- �i��
--      or_temp_tab.quant_r := ir_get_data.quant_r ;  -- �˗���
--      or_temp_tab.quant_i := ir_get_data.quant_i ;  -- ���ɐ�
--      or_temp_tab.quant_o := ir_get_data.quant_o ;  -- �o�ɐ�
--
    -- ���b�g�Ǘ��i�̏ꍇ
--    ELSIF ( ir_get_data.lot_ctl = gc_lot_ctl_y ) THEN
-- del end ver1.1
-- 2008/07/24 A.Shiina v1.7 ADD Start
--
    -- �ϐ�������
    ln_cnt := 0;
--
    -- �ړ����b�g�ڍ׃A�h�I�����݃`�F�b�N
    SELECT  COUNT(1)
    INTO    ln_cnt
    FROM    xxinv_mov_lot_details   xmld    -- �ړ����b�g�ڍ׃A�h�I��
    WHERE   xmld.document_type_code = DECODE( ir_get_data.order_type
                                            ,gc_sp_class_ship, gc_doc_type_ship
                                            ,gc_sp_class_prov, gc_doc_type_prov
                                            ,gc_sp_class_move, gc_doc_type_move )
    AND   xmld.mov_line_id          = ir_get_data.order_line_id
    AND   xmld.lot_id               = ir_get_data.lot_id
    ;
--
-- 2008/07/24 A.Shiina v1.7 ADD End
    -- ���b�g���擾
    BEGIN
-- 2008/07/24 A.Shiina v1.7 ADD Start
    -- �ړ����b�g�ڍ׃A�h�I���ɑ��݂���ꍇ
      IF (ln_cnt > 0) THEN
-- 2008/07/24 A.Shiina v1.7 ADD End
--
        --SELECT                                                             -- 2008/12/03 �{�ԏ�Q#333 Del
        SELECT  /*+ leading(xmld ilm gic mcb) use_nl(xmld ilm gic mcb) */    -- 2008/12/03 �{�ԏ�Q#333 Add
               --ilm.lot_no                                                  -- del ver1.1
               xmld.lot_no                                                   -- add ver1.1
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              ,ilm.attribute2
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute3 )
              ,xlv.meaning
-- mod satart ver1.1
--              ,SUM( CASE
--                      WHEN xmld.record_type_code = gc_rec_type_inst THEN xmld.actual_quantity
--                      ELSE 0
--                    END )
--              ,SUM( CASE
--                      WHEN xmld.record_type_code = gc_rec_type_dlvr THEN xmld.actual_quantity
--                      ELSE 0
--                    END )
--              ,SUM( CASE
--                      WHEN xmld.record_type_code = gc_rec_type_stck THEN xmld.actual_quantity
--                      ELSE 0
--                    END )
              --***************************************************************************
              --*  �w�����b�g�i�˗����j
              --***************************************************************************
              ,SUM( CASE
                 --WHEN (xmld.record_type_code = gc_rec_type_inst) THEN        2008/11/17 �����w�E#651 Del
                 -- 2008/11/17 �����w�E#651 Add Start ------------------------------
                 --********************************
                 --*  �w���Ȃ�����
                 --********************************
                 WHEN (xmld.record_type_code = gc_rec_type_inst)
                   AND (ir_get_data.no_instr_actual = gc_yn_div_y) THEN 
                 -- 2008/11/17 �����w�E#651 Add End --------------------------------
-- mod start ver1.3
                   CASE
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- �Ɩ���ʂ��o��
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- �i�ڋ敪�����i
--                               AND ir_get_data.conv_unit IS NOT NULL THEN -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ�
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')               -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                         -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- ���Z����
---- mod start ver1.2
----                              (xmld.actual_quantity/ir_get_data.num_of_cases)
--                                  ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
---- mod end ver1.2
--
                           --ROUND((NVL(xmld.actual_quantity, ir_get_data.quant_r)        -- 2008/10/20 �ۑ�T_S_486 Del
                           --        /ir_get_data.num_of_cases),3)                        -- 2008/10/20 �ۑ�T_S_486 Del
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)       -- 2008/10/20 �ۑ�T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                         ELSE
                           -- ���Z���Ȃ�
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              xmld.actual_quantity
--
                           --NVL(xmld.actual_quantity, ir_get_data.quant_r) -- 2008/10/20 �ۑ�T_S_486 Del
                           ir_get_data.quant_r                              -- 2008/10/20 �ۑ�T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- �Ɩ���ʂ��x��
                       -- ���Z���Ȃ�
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                            xmld.actual_quantity
--
                       --NVL(xmld.actual_quantity, ir_get_data.quant_r) -- 2008/10/20 �ۑ�T_S_486 Del
                       ir_get_data.quant_r                              -- 2008/10/20 �ۑ�T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                     ELSE   -- �Ɩ���ʂ��o�ׁE�x���ȊO
                       CASE 
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- �i�ڋ敪�����i
--                               AND ir_get_data.conv_unit IS NOT NULL      -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ�
--                               AND ir_get_data.prod_class_code = '2' THEN -- ���i�敪���h�����N
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- ���i�敪���h�����N�A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')             -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                       -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- ���Z����
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                                  ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
--
                           --ROUND((NVL(xmld.actual_quantity, ir_get_data.quant_r)             -- 2008/10/20 �ۑ�T_S_486 Del
                           --  /ir_get_data.num_of_cases),3)                                   -- 2008/10/20 �ۑ�T_S_486 Del
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)            -- 2008/10/20 �ۑ�T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                         ELSE
                           -- ���Z���Ȃ�
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              xmld.actual_quantity
--
                           --NVL(xmld.actual_quantity, ir_get_data.quant_r) -- 2008/10/20 �ۑ�T_S_486 Del
                           ir_get_data.quant_r                              -- 2008/10/20 �ۑ�T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                       END
                   END
-- mod end ver1.3
--
                 -- 2008/11/17 �����w�E#651 Add Start --------------------------------------------------------
                 --****************************************
                 --*  �w��������т̏ꍇ(�w�����b�g����)
                 --****************************************
                 WHEN (xmld.record_type_code = gc_rec_type_inst)
                   AND (ir_get_data.no_instr_actual = gc_yn_div_n)
                 THEN
                   CASE
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- �Ɩ���ʂ��o��
                       CASE
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- ���Z����
                           ROUND(xmld.actual_quantity / ir_get_data.num_of_cases, 3)
--
                         ELSE   -- ���Z���Ȃ�
                            xmld.actual_quantity
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- �Ɩ���ʂ��x���̏ꍇ�A���Z���Ȃ�
                       xmld.actual_quantity
--
                     ELSE     -- �Ɩ���ʂ��o�ׁE�x���ȊO
                       CASE
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- ���i�敪���h�����N�A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- ���Z����
                           ROUND(xmld.actual_quantity / ir_get_data.num_of_cases, 3)
--
                         ELSE  -- ���Z���Ȃ�
                           xmld.actual_quantity
                       END
                   END
--
                 --****************************************
                 --*  �w��������т̏ꍇ(�w�����b�g�Ȃ�)
                 --****************************************
                 WHEN (ir_get_data.no_instr_actual = gc_yn_div_n)   -- �w���������
                   AND (ir_get_data.lot_inst_cnt = 0)               -- �w�����b�g���O��
                   AND (ir_get_data.row_num = 1)                    -- ���b�g����̏ꍇ�͍ŏ��̃��b�g�ɂ̂ݏo�͂���
                 THEN
                   CASE
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- �Ɩ���ʂ��o��
                       CASE
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- ���Z����
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)
--
                         ELSE  -- ���Z���Ȃ�
                            ir_get_data.quant_r
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- �Ɩ���ʂ��x���̏ꍇ�A���Z���Ȃ�
                       ir_get_data.quant_r
--
                     ELSE     -- �Ɩ���ʂ��o�ׁE�x���ȊO
                       CASE
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- ���i�敪���h�����N�A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- ���Z����
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)
--
                         ELSE   -- ���Z���Ȃ�
                           ir_get_data.quant_r
                       END
                   END
                   -- 2008/11/17 �����w�E#651 Add End ---------------------------------------------------------
--
                 ELSE 0
              END )
--
              --*********************************************
              --*  ���Ɏ��у��b�g�i���ɐ��j
              --**********************************************
              ,SUM( CASE
                 WHEN (xmld.record_type_code = gc_rec_type_dlvr) THEN
-- mod start ver1.3
                   CASE 
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- �Ɩ���ʂ��o��
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- �i�ڋ敪�����i
--                               AND ir_get_data.conv_unit IS NOT NULL THEN -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ�
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- ���Z����
                           --(xmld.actual_quantity/ir_get_data.num_of_cases)           -- del ver1.2
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)    -- add ver1.2
--
                         ELSE  -- ���Z���Ȃ�
                           xmld.actual_quantity
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- �Ɩ���ʂ��x���̏ꍇ�A���Z���Ȃ�
                       xmld.actual_quantity
--
                     ELSE
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- �i�ڋ敪�����i
--                               AND ir_get_data.conv_unit IS NOT NULL      -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ�
--                               AND ir_get_data.prod_class_code = '2' THEN -- ���i�敪���h�����N
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- ���i�敪���h�����N�A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- ���Z����
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
--
                         ELSE   -- ���Z���Ȃ�
                           xmld.actual_quantity
                       END
                   END
-- mod end ver1.3
                 ELSE 0
              END )
--
              --*********************************************
              --*  �o�Ɏ��у��b�g�i�o�ɐ��j
              --**********************************************
              ,SUM( CASE
                 WHEN (xmld.record_type_code = gc_rec_type_stck) THEN
-- mod start ver1.3
                   CASE 
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- �Ɩ���ʂ��o��
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- �i�ڋ敪�����i
--                               AND ir_get_data.conv_unit IS NOT NULL THEN -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ�
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- ���Z����
                           --(xmld.actual_quantity/ir_get_data.num_of_cases)          -- del ver1.2
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)   -- Add ver1.2
--
                         ELSE  -- ���Z���Ȃ�
                           xmld.actual_quantity
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- �Ɩ���ʂ��x���̏ꍇ�A���Z���Ȃ�
                       xmld.actual_quantity
--
                     ELSE
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- �i�ڋ敪�����i
--                               AND ir_get_data.conv_unit IS NOT NULL      -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ�
--                               AND ir_get_data.prod_class_code = '2' THEN -- ���i�敪���h�����N
                         -- �i�ڋ敪�����i�A����
                         -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
                         -- ���i�敪���h�����N�A����
                         -- �P�[�X������1�ȏ�̏ꍇ
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 �{�ԏ�Q#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 �{�ԏ�Q#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- ���Z����
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
--
                         ELSE   -- ���Z���Ȃ�
                           xmld.actual_quantity
                       END
                   END
-- mod end ver1.3
                 ELSE 0
              END )
-- mod end ver1.1
        INTO   or_temp_tab.lot_no           -- ���b�g�ԍ�
              ,or_temp_tab.product_date     -- ������
              ,or_temp_tab.original_char    -- �ŗL�L��
              ,or_temp_tab.use_by_date      -- �ܖ�����
              ,or_temp_tab.lot_status       -- �i��
              ,or_temp_tab.quant_r          -- �˗���
              ,or_temp_tab.quant_i          -- ���ɐ�
              ,or_temp_tab.quant_o          -- �o�ɐ�
        FROM ic_lots_mst              ilm     -- OPM���b�g�}�X�^
            ,xxinv_mov_lot_details    xmld    -- �ړ����b�g�ڍ׃A�h�I��
            ,xxcmn_lookup_values_v    xlv     -- �N�C�b�N�R�[�h���VIEW
            --,xxcmn_item_categories4_v xicv    -- �n�o�l�i�ڃJ�e�S���������VIEW4  -- add ver1.1 -- 2008/12/03 �{�ԏ�Q#333 Del
            ,gmi_item_categories      gic                                                         -- 2008/12/03 �{�ԏ�Q#333 Add
            ,mtl_categories_b         mcb                                                         -- 2008/12/03 �{�ԏ�Q#333 Add
        -- del start ver1.1 ------------------------------------------------------
        --WHERE xlv.lookup_type         = gc_lookup_lot_status
        --AND   ilm.attribute23         = xlv.lookup_code
        --AND   xmld.actual_date        BETWEEN gr_param.date_from
        --                             AND     NVL( gr_param.date_to, xmld.actual_date )
        -- del end ver1.1 --------------------------------------------------------
        -- add start ver1.1 ------------------------------------------------------
        WHERE xlv.lookup_type(+)      = gc_lookup_lot_status
        AND   ilm.attribute23         = xlv.lookup_code(+)
        -- del start ver1.2-------------------------------
        --AND ((xmld.actual_date IS NULL)
        --      OR
        --     ((xmld.actual_date IS NOT NULL)
        --       AND
        --       (xmld.actual_date      BETWEEN gr_param.date_from
        --                              AND     NVL( gr_param.date_to, xmld.actual_date ))))
        -- del end ver1.2---------------------------------
        -- add end ver1.1 --------------------------------------------------------
        AND   xmld.document_type_code = DECODE( ir_get_data.order_type
                                               ,gc_sp_class_ship, gc_doc_type_ship
                                               ,gc_sp_class_prov, gc_doc_type_prov
                                               ,gc_sp_class_move, gc_doc_type_move )
        AND   xmld.mov_line_id        = ir_get_data.order_line_id
        AND   xmld.lot_id             = ir_get_data.lot_id      -- add ver1.2
        AND   ilm.lot_id              = xmld.lot_id
        AND   ilm.item_id             = xmld.item_id
        --AND   ilm.item_id             = xicv.item_id            -- add ver1.1  -- 2008/12/03 �{�ԏ�Q#333 Del
        AND   ilm.item_id             = gic.item_id                              -- 2008/12/03 �{�ԏ�Q#333 Add
        AND   gic.category_set_id     = cn_item_class_id                         -- 2008/12/03 �{�ԏ�Q#333 Add
        AND   gic.category_id         =mcb.category_id                           -- 2008/12/03 �{�ԏ�Q#333 Add
        AND   ilm.item_id             = ir_get_data.item_id
        --GROUP BY ilm.lot_no                                   -- del ver1.1
        GROUP BY xmld.lot_no                                    -- add ver1.1
                ,ilm.attribute1
                ,ilm.attribute2
                ,ilm.attribute3
                ,xlv.meaning
        ;
--
-- 2008/07/24 A.Shiina v1.7 ADD Start
      -- �ړ����b�g�ڍ׃A�h�I���ɑ��݂��Ȃ��ꍇ
      ELSE
        or_temp_tab.lot_no        := NULL ;   -- ���b�g�ԍ�
        or_temp_tab.product_date  := NULL ;   -- ������
        or_temp_tab.use_by_date   := NULL ;   -- �ܖ�����
        or_temp_tab.original_char := NULL ;   -- �ŗL�L��
        or_temp_tab.lot_status    := NULL ;   -- �i��
--
        --***************************
        --*  �˗���
        --***************************
        -- �Ɩ���ʂ��o��
        IF (ir_get_data.order_type = gc_sp_class_ship) THEN
          -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
          -- �P�[�X������1�ȏ�̏ꍇ
          IF ((ir_get_data.conv_unit IS NOT NULL)
            AND (ir_get_data.num_of_cases > 0)) THEN
            or_temp_tab.quant_r := ROUND((ir_get_data.quant_r/ir_get_data.num_of_cases),3);
          ELSE
            or_temp_tab.quant_r := ir_get_data.quant_r ;
          END IF;
        -- �Ɩ���ʂ��x��
        ELSIF (ir_get_data.order_type = gc_sp_class_prov) THEN
          or_temp_tab.quant_r := ir_get_data.quant_r ;
        ELSE
          -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��A����
          -- ���i�敪���h�����N�A����
          -- �P�[�X������1�ȏ�̏ꍇ
          IF ((ir_get_data.conv_unit IS NOT NULL)
            AND (ir_get_data.prod_class_code = '2')
            AND (ir_get_data.num_of_cases > 0)) THEN
            or_temp_tab.quant_r := ROUND((ir_get_data.quant_r/ir_get_data.num_of_cases),3);
          ELSE
            or_temp_tab.quant_r := ir_get_data.quant_r ;
          END IF;
        END IF;
--
        --***************************
        --*  ���ɐ�
        --***************************
        or_temp_tab.quant_i := ir_get_data.quant_i ;
--
        --***************************
        --*  �o�ɐ�
        --***************************
        or_temp_tab.quant_o := ir_get_data.quant_o ;
--
      END IF;
-- 2008/07/24 A.Shiina v1.7 ADD End
-- 2008/07/24 A.Shiina v1.7 ADD Start
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.lot_no        := NULL ;
        or_temp_tab.product_date  := NULL ;
        or_temp_tab.use_by_date   := NULL ;
        or_temp_tab.original_char := NULL ;
        or_temp_tab.lot_status    := NULL ;
        or_temp_tab.quant_r       := 0 ;
        or_temp_tab.quant_i       := 0 ;
        or_temp_tab.quant_o       := 0 ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.lot_no        := NULL ;
        or_temp_tab.product_date  := NULL ;
        or_temp_tab.use_by_date   := NULL ;
        or_temp_tab.original_char := NULL ;
        or_temp_tab.lot_status    := NULL ;
        or_temp_tab.quant_r       := 0 ;
        or_temp_tab.quant_i       := 0 ;
        or_temp_tab.quant_o       := 0 ;
    END ;
--
-- del start ver1.1
--    END IF ;
-- del end ver1.1
--
-- 2008/07/24 A.Shiina v1.7 ADD Start
    -- �ϐ�������
    lv_reserved_status := NULL;
-- 2008/07/24 A.Shiina v1.7 ADD End
--
    --------------------------------------------------
    -- ���َ��R�ݒ�
    --------------------------------------------------
    -- �ۗ��X�e�[�^�X
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
/*  BEGIN
      SELECT DISTINCT  xsli.reserved_status
      INTO   lv_reserved_status
      FROM xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
          ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
      WHERE xshi.header_id        = xsli.header_id
      AND   xshi.delivery_no      = ir_get_data.delivery_no   -- �z���m��
      AND   xshi.order_source_ref = ir_get_data.request_no    -- �˗��m��
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_reserved_status := NULL ;
    END ;
*/--
    -- �ϐ�������
    lv_eos_data_type   := NULL;
    lv_reserved_status := NULL;
--
    -- �ۗ��X�e�[�^�X����
    -- EOS�f�[�^��ʎ擾
    BEGIN
      SELECT DISTINCT
              xsli.reserved_status
             --,xshi.eos_data_type    -- 2008/10/17 �ύX�v��#210�Ή� Del
      INTO    lv_reserved_status
             --,lv_eos_data_type      -- 2008/10/17 �ύX�v��#210�Ή� Del
      FROM    xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
             ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
      WHERE  xshi.header_id        = xsli.header_id
      --AND    xshi.delivery_no  = ir_get_data.delivery_no   -- �z���m��                                        2008/10/31 �����w�E#461 Del
      AND    NVL(xshi.delivery_no,gv_nvl_null_char) = NVL(ir_get_data.delivery_no,gv_nvl_null_char) -- �z���m�� 2008/10/31 �����w�E#461 Add
      AND    xshi.order_source_ref = ir_get_data.request_no    -- �˗��m��
      ;
--
      lv_eos_data_type := ir_get_data.order_type;   -- 2008/10/17 �ύX�v��#210�Ή� Add
--
      IF ((lv_reserved_status = gc_reserved_status_y)
        AND (lv_eos_data_type IN (cv_eos_data_cd_200
                                 ,cv_eos_data_cd_210
                                 ,cv_eos_data_cd_215
                                 ,cv_eos_data_cd_220))) THEN
        ln_quant_kbn := 1;    -- �ۗ����o�ɑΏ�
      ELSIF ((lv_reserved_status = gc_reserved_status_y)
        AND (lv_eos_data_type = cv_eos_data_cd_230)) THEN
        ln_quant_kbn := 2;    -- �ۗ������ɑΏ�
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_eos_data_type   := NULL ;
        lv_reserved_status := NULL ;
    END ;
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
    ------------------------------
    -- �ۗ��X�e�[�^�X�F�u�ۗ��v
    ------------------------------
    IF ( lv_reserved_status = gc_reserved_status_y ) THEN
--
      IF ( ir_get_data.status IS NULL ) THEN -- �ۗ��f�[�^�̏ꍇ  2008/10/20 �����e�X�g��Q#394(2) Add
--
        -- 2008/07/24 A.Shiina v1.7 UPDATE Start ----------------------------------------------
        --or_temp_tab.quant_r       := ir_get_data.quant_r ;  -- �˗���
        --or_temp_tab.quant_i       := ir_get_data.quant_i ;  -- ���ɐ�
        --or_temp_tab.quant_o       := ir_get_data.quant_o ;  -- �o�ɐ�
--
        or_temp_tab.quant_r       := 0 ;  -- �˗���
--
        -- �o�ɑΏۂ̏ꍇ
        IF (ln_quant_kbn = 1) THEN
          or_temp_tab.quant_i       := 0 ;                                              -- ���ɐ�
          or_temp_tab.quant_o       := NVL(ir_get_data.quant_d, ir_get_data.quant_r) ;  -- �o�ɐ�
        -- ���ɑΏۂ̏ꍇ
        ELSIF (ln_quant_kbn = 2) THEN
          or_temp_tab.quant_i       := NVL(ir_get_data.quant_d, ir_get_data.quant_r) ;  -- ���ɐ�
          or_temp_tab.quant_o       := 0 ;                                              -- �o�ɐ�
        END IF;
        -- 2008/07/24 A.Shiina v1.7 UPDATE End -----------------------------------------------
--
        -- ���b�g���擾
        BEGIN
          SELECT xsli.lot_no
                ,xsli.designated_production_date
                ,xsli.use_by_date
                ,xsli.original_character
                ,NULL
          INTO   or_temp_tab.lot_no
                ,or_temp_tab.product_date
                ,or_temp_tab.use_by_date
                ,or_temp_tab.original_char
                ,or_temp_tab.lot_status         -- �i��
          FROM xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
              ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
          WHERE xsli.line_id          = ir_get_data.order_line_id
          AND   xshi.header_id        = xsli.header_id
          --AND   xshi.delivery_no = ir_get_data.delivery_no  -- �z���m��                                          2008/10/31 �����w�E#461 Del
          AND   NVL(xshi.delivery_no,gv_nvl_null_char) = NVL(ir_get_data.delivery_no,gv_nvl_null_char) -- �z���m�� 2008/10/31 �����w�E#461 Add
          AND   xshi.order_source_ref = ir_get_data.request_no    -- �˗��m��
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            or_temp_tab.lot_no        := NULL ;
            or_temp_tab.product_date  := NULL ;
            or_temp_tab.use_by_date   := NULL ;
            or_temp_tab.original_char := NULL ;
            or_temp_tab.lot_status    := NULL ;
          WHEN TOO_MANY_ROWS THEN
            or_temp_tab.lot_no        := NULL ;
            or_temp_tab.product_date  := NULL ;
            or_temp_tab.use_by_date   := NULL ;
            or_temp_tab.original_char := NULL ;
            or_temp_tab.lot_status    := NULL ;
        END ;
--
      END IF;  -- 2008/10/20 �����e�X�g��Q#394(2) Add
--
      or_temp_tab.reason := gc_reason_rsrv ;  -- �ۗ�
--
    ELSE
      ------------------------------
      -- �o�ׁE�x���̏ꍇ
      ------------------------------
      IF ( ir_get_data.order_type IN( gc_sp_class_ship
                                     ,gc_sp_class_prov ) ) THEN
        ------------------------------
        -- ���ߍρE��̍ς̏ꍇ
        ------------------------------
        IF ( ir_get_data.status IN( gc_req_status_s_cmpb             -- �o�ׁF���ߍ�
                                   ,gc_req_status_p_cmpb ) ) THEN    -- �x���F��̍�
          ------------------------------
          -- �w����������т������ꍇ
          ------------------------------
          IF (   ( or_temp_tab.quant_r > 0 )
             AND ( or_temp_tab.quant_o = 0 ) ) THEN
--
            or_temp_tab.reason        := gc_reason_nrep ;     -- ����
--
          END IF ;
--
        ------------------------------
        -- �o�׎��ьv��ς̏ꍇ
        ------------------------------
        ELSIF ( ir_get_data.status IN( gc_req_status_s_cmpc             -- �o�ׁF�o�׎��ьv���
                                      ,gc_req_status_p_cmpc ) ) THEN    -- �x���F�o�׎��ьv���
          ------------------------------
          -- �w�b�_�[���x���̃`�F�b�N
          ------------------------------
          -- �w���Ǝ��т̈قȂ郌�R�[�h���擾����
          SELECT COUNT( xoha.order_header_id )
          INTO   ln_temp_cnt
          FROM   xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
          WHERE (  xoha.career_id             <> xoha.result_freight_carrier_id       -- �^���Ǝ�
                OR xoha.shipping_method_code  <> xoha.result_shipping_method_code     -- �z���敪
                OR xoha.deliver_to_id         <> xoha.result_deliver_to_id            -- �o�א�
                OR xoha.schedule_ship_date    <> xoha.shipped_date                    -- �o�ד�
                OR xoha.schedule_arrival_date <> xoha.arrival_date                )   -- ���ד�
          AND   xoha.latest_external_flag = gc_yn_div_y             -- �ŐV
          AND   xoha.request_no           = ir_get_data.request_no  -- �˗��m��
          ;
          ------------------------------
          -- �w���Ǝ��т��قȂ�ꍇ
          ------------------------------
          IF ( ln_temp_cnt > 0 ) THEN
--
            or_temp_tab.reason := gc_reason_diff ;  -- �˗���
--
          ------------------------------
          -- �w���Ǝ��т�����̏ꍇ
          ------------------------------
          ELSE
            ------------------------------
            -- �˗����Əo�א�������̏ꍇ
            ------------------------------
            IF ( or_temp_tab.quant_r = or_temp_tab.quant_o ) THEN
--
              or_temp_tab.reason        := NULL ;               -- ���قȂ�
--
            ------------------------------
            -- �˗����Əo�א����قȂ�ꍇ
            ------------------------------
            ELSE
--
              or_temp_tab.reason := gc_reason_diff ;  -- �˗���
--
            END IF ;
--
          END IF ;
--
        END IF ;
--
      ------------------------------
      -- �ړ��̏ꍇ
      ------------------------------
      ELSE
        ------------------------------
        -- �˗��ρE�������̏ꍇ
        ------------------------------
        IF ( ir_get_data.status IN( gc_mov_status_cmp             -- �˗���
                                   ,gc_mov_status_adj ) ) THEN    -- ������
          ------------------------------
          -- �w����������т������ꍇ
          ------------------------------
          IF (   ( or_temp_tab.quant_r > 0 )
             AND ( or_temp_tab.quant_o = 0 ) ) THEN
--
            or_temp_tab.reason        := gc_reason_nrep ;     -- ����
--
          END IF ;
--
        ------------------------------
        -- �˗��ρE�������ȊO�̏ꍇ
        ------------------------------
        ELSE
          ------------------------------
          -- �w�b�_�[���x���̃`�F�b�N
          ------------------------------
          -- �w���Ǝ��т̈قȂ郌�R�[�h���擾����
          SELECT COUNT( xmrih.mov_hdr_id )
          INTO   ln_temp_cnt
          FROM   xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          WHERE (  xmrih.career_id             <> xmrih.actual_career_id                -- �^���Ǝ�
                OR xmrih.shipping_method_code  <> xmrih.actual_shipping_method_code     -- �z���敪
                OR xmrih.schedule_ship_date    <> xmrih.actual_ship_date                -- �o�ד�
                OR xmrih.schedule_arrival_date <> xmrih.actual_arrival_date         )   -- ���ד�
          AND   xmrih.mov_num                   = or_temp_tab.request_no  -- �ړ��m��
          ;
          ------------------------------
          -- �w���Ǝ��т��قȂ�ꍇ
          ------------------------------
          IF ( ln_temp_cnt > 0 ) THEN
--
            -- ���ɕ񍐗L�̏ꍇ
            IF ( ir_get_data.status = gc_mov_status_stc ) THEN
              or_temp_tab.reason := gc_reason_ndel ;  -- �o�ɖ�
--
            -- �o�ɕ񍐗L�̏ꍇ
            ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
              or_temp_tab.reason := gc_reason_nstc ;  -- ���ɖ�
--
            -- ���o�ɕ񍐗L�̏ꍇ
            ELSIF ( ir_get_data.status = gc_mov_status_dsr ) THEN
              or_temp_tab.reason := gc_reason_diff ;  -- �˗���
--
            END IF ;
--
          ------------------------------
          -- �w���Ǝ��т�����̏ꍇ
          ------------------------------
          ELSE
            ------------------------------
            -- ���ɕ񍐗L�̏ꍇ
            ------------------------------
            IF ( ir_get_data.status = gc_mov_status_stc ) THEN
-- mod start ver1.2
              -- �˗����Ɠ��ɐ��������ꍇ
--              IF ( or_temp_tab.quant_r = or_temp_tab.quant_i ) THEN
--                or_temp_tab.reason        := NULL ;               -- ���قȂ�
--
              -- �˗����Ɠ��ɐ����قȂ�ꍇ
--              ELSE
--                or_temp_tab.reason := gc_reason_ndel ;  -- �o�ɖ�
--
--              END IF ;
              or_temp_tab.reason := gc_reason_ndel ;  -- �o�ɖ�
-- mod end ver1.2
--
            ------------------------------
            -- �o�ɕ񍐗L�̏ꍇ
            ------------------------------
            ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
-- mod start ver1.2
              -- �˗����Əo�ɐ��������ꍇ
--              IF ( or_temp_tab.quant_r = or_temp_tab.quant_o ) THEN
--                or_temp_tab.reason        := NULL ;               -- ���قȂ�
--
              -- �˗����Əo�ɐ����قȂ�ꍇ
--              ELSE
--                or_temp_tab.reason := gc_reason_nstc ;  -- ���ɖ�
--
--              END IF ;
              or_temp_tab.reason := gc_reason_nstc ;  -- ���ɖ�
-- mod end ver1.2
--
            ------------------------------
            -- ���o�ɕ񍐗L�̏ꍇ
            ------------------------------
            ELSIF ( ir_get_data.status = gc_mov_status_dsr ) THEN
              ------------------------------
              -- ���ɐ��Əo�ɐ����قȂ�ꍇ
              ------------------------------
              IF ( or_temp_tab.quant_i <> or_temp_tab.quant_o ) THEN
                or_temp_tab.reason        := gc_reason_iodf ;     -- �o����
--
              ------------------------------
              -- ���ɐ��Əo�ɐ�������̏ꍇ
              ------------------------------
              ELSE
                ------------------------------
                -- �˗����Ɠ��ɐ����قȂ� or
                -- �˗����Əo�ɐ����قȂ�ꍇ
                ------------------------------
                IF (  ( or_temp_tab.quant_r <> or_temp_tab.quant_i )
                   OR ( or_temp_tab.quant_r <> or_temp_tab.quant_o ) ) THEN
                  or_temp_tab.reason := gc_reason_diff ;  -- �˗���
--
                ------------------------------
                -- ��L�ȊO�̏ꍇ
                ------------------------------
                ELSE
                  or_temp_tab.reason        := NULL ;               -- ���قȂ�
--
                END IF ;
--
              END IF ;
--
            END IF ;
--
          END IF ;
--
        END IF ;
--
      END IF ;
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
  END prc_set_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_ship_data
   * Description      : �o�ׁE�x���f�[�^���o����
   ************************************************************************************************/
  PROCEDURE prc_create_ship_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_ship_data' ; -- �v���O������
--
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')); -- 2008/12/03 �{�ԏ�Q#333 Add
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')); -- 2008/12/03 �{�ԏ�Q#333 Add
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lr_get_data       rec_get_data ;        -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
    lr_temp_tab       rec_temp_tab_data ;   -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
--
    -- ==================================================
    -- �J  �[  �\  ��  ��  ��
    -- ==================================================
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Del Start
    ---------------------------------------------------------------------------------------------------------------------
    /*
    -- �w���E���уf�[�^�擾�J�[�\��
    CURSOR cu_main
    IS
    --***************************************
    --* �w��
    --***************************************
-- mod start ver1.1
--      SELECT xil.segment1                 AS location_code      -- �o�ɑq�ɃR�[�h
      SELECT xoha.deliver_from            AS location_code      -- �o�ɑq�ɃR�[�h
            --,xil.description              AS location_name      -- �o�ɑq�ɖ��� 2008/10/10 �����e�X�g��Q#338 Del
            ,SUBSTRB(xil.description,1,20) AS location_name      -- �o�ɑq�ɖ���  2008/10/10 �����e�X�g��Q#338 Add
            ,xoha.schedule_ship_date      AS ship_date          -- �o�ɓ�
            ,xoha.schedule_arrival_date   AS arvl_date          -- ���ɓ�
            ,xoha.head_sales_branch       AS head_sales_branch  -- ���������F�Ǌ����_
--            ,xoha.po_no                   AS po_no              -- ���������F�Ǌ����_
-- mod end ver1.1
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN xoha.deliver_to_id
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                          AS deliver_id         -- ���������F�z����
            ,xoha.career_id               AS career_id          -- ���������F�^���Ǝ�
            ,xoha.shipping_method_code    AS ship_method_code   -- ���������F�z���敪
            ,otta.attribute1              AS order_type         -- �Ɩ���ʁi�R�[�h�j
            ,xoha.delivery_no             AS delivery_no        -- �z���m��
            ,xoha.request_no              AS request_no         -- �˗��m��
            ,xola.order_line_id           AS order_line_id      -- ���������F���ׂh�c
            ,ximv.item_id                 AS item_id            -- ���������F�i�ڂh�c
            ,ximv.item_no                 AS item_code          -- �i�ڃR�[�h
            ,ximv.item_short_name         AS item_name          -- �i�ږ���
            ,ximv.lot_ctl                 AS lot_ctl            -- ���������F���b�g�g�p
            --,NVL( xola.based_request_quantity, 0 )  AS quant_r  -- �˗����i���b�g�Ǘ��O�j--2008/10/17 �����e�X�g��Q#146 Del
            ,NVL( xola.quantity, 0 )  AS quant_r                -- �˗����i���b�g�Ǘ��O�j  --2008/10/17 �����e�X�g��Q#146 Add
            ,NVL( xola.ship_to_quantity      , 0 )  AS quant_i  -- ���ɐ��i���b�g�Ǘ��O�j
            ,NVL( xola.shipped_quantity      , 0 )  AS quant_o  -- �o�ɐ��i���b�g�Ǘ��O�j
            ,xoha.req_status              AS status             -- �w�b�_�X�e�[�^�X
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ���b�gID
            ,ximv.conv_unit               AS conv_unit             -- ���o�Ɋ��Z�P��
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- �P�[�X����
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- �P�[�X����
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xoha.freight_charge_class    AS freight_charge_code   -- �^���敪
            --,xcv.complusion_output_code   AS complusion_output_kbn -- �����o�͋敪       -- 2008/10/31 �����w�E#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪  -- 2008/10/31 �����w�E#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
-- add end ver1.2
-- 2008/11/17 �����w�E#651 Add Start ------------------------------------------------------
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code IN ( gc_doc_type_ship, gc_doc_type_prov)
                AND xmld2.record_type_code = gc_rec_type_inst  -- �w�����b�g
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- �w�����b�g�̌���
            ,ROW_NUMBER() OVER (PARTITION BY xoha.request_no
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num            -- �˗�No�E�i�ڂ��ƂɃ��b�gID������1����̔�
-- 2008/11/17 �����w�E#651 Add End --------------------------------------------------------
      FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld       -- �ړ����b�g�ڍ׃A�h�I��
            WHERE  xmld.document_type_code IN( gc_doc_type_ship, gc_doc_type_prov)
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld
-- add end ver1.2
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
          ,xxcmn_item_locations2_v    xil       -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v          ximv      -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v   xicv      -- �n�o�l�i�ڃJ�e�S���������VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- �^���Ǝҏ��VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = gr_param.item_div
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xola.shipping_item_code = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- �󒍖��׃A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   NVL( xola.delete_flag, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
      AND   xoha.order_header_id                 = xola.order_header_id
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xola.order_line_id
      AND   xmld.mov_line_id(+)        = xola.order_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
-- del start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
-- 2008/07/24 A.Shiina v1.7 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xoha.deliver_from_id  = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      ----------------------------------------------------------------------------------------------
      AND   otta.order_category_code  = gc_order_cat_o
      AND   otta.attribute1          IN( gc_sp_class_ship     -- �o�׈˗�
                                        ,gc_sp_class_prov )   -- �x���˗�
      AND   xoha.order_type_id        = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   xoha.req_status IN( gc_req_status_s_cmpb    -- �o�ׁF���ς�
                               ,gc_req_status_s_cmpc    -- �o�ׁF�o�׎��ьv���
                               ,gc_req_status_p_cmpb    -- �x���F��̍�
                               ,gc_req_status_p_cmpc )  -- �x���F�o�׎��ьv���
      AND   xoha.latest_external_flag = gc_yn_div_y     -- �ŐV
      -- �p�����[�^�����D�w������
      AND   xoha.instruction_dept = NVL( gr_param.dept_code, xoha.instruction_dept )
      -- �p�����[�^�����D�o�Ɍ`��
      AND   xoha.order_type_id    = NVL( gr_param.deliver_type_id, xoha.order_type_id )
      -- �p�����[�^�����D�˗��m��
      AND   xoha.request_no       = NVL( gr_param.request_no, xoha.request_no )
-- add start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
      AND   xoha.deliver_from     = NVL( gr_param.deliver_from, xoha.deliver_from )
-- add end ver1.1
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.date_from
                                    AND     NVL( gr_param.date_to, xoha.schedule_ship_date )
--
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xoha.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xoha.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xoha.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 �����w�E#461 Del End ---------------------------------------
--
      -- 2008/10/31 �����w�E#461 Add Start -------------------------------------
      AND   NVL(xoha.career_id,gn_nvl_null_num)  =    xcv.party_id(+)
      AND   xoha.schedule_ship_date             >=    xcv.start_date_active(+)
      AND   xoha.schedule_ship_date             <=    xcv.end_date_active(+)
      -- 2008/10/31 �����w�E#461 Add End ---------------------------------------
--
      UNION
      --***************************************
      --* ����
      --***************************************
-- mod start ver1.1
      SELECT xoha.deliver_from                  AS location_code    -- �o�ɑq�ɃR�[�h
--      SELECT xil.segment1                       AS location_code    -- �o�ɑq�ɃR�[�h
            --,xil.description                    AS location_name    -- �o�ɑq�ɖ��� 2008/10/10 �����e�X�g��Q#338 Del
            ,SUBSTRB(xil.description,1,20)      AS location_name    -- �o�ɑq�ɖ���   2008/10/10 �����e�X�g��Q#338 Add
            ,NVL( xoha.shipped_date
                 ,xoha.schedule_ship_date    )  AS ship_date        -- �o�ɓ�
            ,NVL( xoha.arrival_date
                 ,xoha.schedule_arrival_date )  AS arvl_date        -- ���ɓ�
            ,xoha.head_sales_branch             AS head_sales_branch -- ���������F�Ǌ����_
--            ,xoha.po_no                         AS po_no            -- ���������F�Ǌ����_
-- mod end ver1.1
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN NVL( xoha.result_deliver_to_id, xoha.deliver_to_id )
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                                AS deliver_id       -- ���������F�z����
            ,NVL( xoha.result_freight_carrier_id
                 ,xoha.career_id )              AS career_id        -- ���������F�^���Ǝ�
            ,NVL( xoha.result_shipping_method_code
                 ,xoha.shipping_method_code )   AS ship_method_code -- ���������F�z���敪
            ,otta.attribute1                    AS order_type       -- �Ɩ���ʁi�R�[�h�j
            ,xoha.delivery_no                   AS delivery_no      -- �z���m��
            ,xoha.request_no                    AS request_no       -- �˗��m��
            ,xola.order_line_id                 AS order_line_id    -- ���������F���ׂh�c
            ,ximv.item_id                       AS item_id          -- ���������F�i�ڂh�c
            ,ximv.item_no                       AS item_code        -- �i�ڃR�[�h
            ,ximv.item_short_name               AS item_name        -- �i�ږ���
            ,ximv.lot_ctl                       AS lot_ctl          -- ���������F���b�g�g�p
            --,NVL( xola.based_request_quantity, 0 )  AS quant_r      -- �˗����i���b�g�Ǘ��O�j--2008/10/17 �����e�X�g��Q#146 Del
            ,NVL( xola.quantity, 0 )  AS quant_r                    -- �˗����i���b�g�Ǘ��O�j  --2008/10/17 �����e�X�g��Q#146 Add
            ,NVL( xola.ship_to_quantity      , 0 )  AS quant_i      -- ���ɐ��i���b�g�Ǘ��O�j
            ,NVL( xola.shipped_quantity      , 0 )  AS quant_o      -- �o�ɐ��i���b�g�Ǘ��O�j
            ,xoha.req_status                    AS status           -- �w�b�_�X�e�[�^�X
-- add start ver1.2
            ,xmld.lot_id                        AS lot_id           -- ���b�gID
            ,ximv.conv_unit                     AS conv_unit        -- ���o�Ɋ��Z�P��
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases  -- �P�[�X����
            ,TO_NUMBER(ximv.num_of_cases)       AS num_of_cases  -- �P�[�X����
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xoha.freight_charge_class          AS freight_charge_code   -- �^���敪
            --,xcv.complusion_output_code         AS complusion_output_kbn -- �����o�͋敪  -- 2008/10/31 �����w�E#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪   -- 2008/10/31 �����w�E#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
-- add end ver1.2
-- 2008/11/17 �����w�E#651 Add Start ----------------------------------------------------------------
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code IN ( gc_doc_type_ship, gc_doc_type_prov)
                AND xmld2.record_type_code = gc_rec_type_inst  -- �w�����b�g
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- �w�����b�g�̌���
            ,ROW_NUMBER() OVER (PARTITION BY xoha.request_no
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- �˗�No�E�i�ڂ��ƂɃ��b�gID������1����̔�
-- 2008/11/17 �����w�E#651 Add End -----------------------------------------------------------------
      FROM xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld   -- �ړ����b�g�ڍ׃A�h�I��
            WHERE  xmld.document_type_code IN( gc_doc_type_ship, gc_doc_type_prov)
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld
-- add end ver1.2
          ,xxcmn_item_locations2_v    xil       -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v          ximv      -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v   xicv      -- �n�o�l�i�ڃJ�e�S���������VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- �^���Ǝҏ��VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = gr_param.item_div
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xola.shipping_item_code = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- �󒍖��׃A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   NVL( xola.delete_flag, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
      AND   xoha.order_header_id                 = xola.order_header_id
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xola.order_line_id
      AND   xmld.mov_line_id(+)        = xola.order_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
-- del start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
-- 2008/07/24 A.Shiina v1.7 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xoha.deliver_from_id  = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- �󒍃^�C�v
      ----------------------------------------------------------------------------------------------
      AND   otta.order_category_code  = gc_order_cat_o
      AND   otta.attribute1          IN( gc_sp_class_ship     -- �o�׈˗�
                                        ,gc_sp_class_prov )   -- �x���˗�
      AND   xoha.order_type_id        = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   xoha.req_status IN( gc_req_status_s_cmpb    -- �o�ׁF���ς�
                               ,gc_req_status_s_cmpc    -- �o�ׁF�o�׎��ьv���
                               ,gc_req_status_p_cmpb    -- �x���F��̍�
                               ,gc_req_status_p_cmpc )  -- �x���F�o�׎��ьv���
      AND   xoha.latest_external_flag = gc_yn_div_y     -- �ŐV
      -- �p�����[�^�����D�w������
      AND   xoha.instruction_dept = NVL( gr_param.dept_code, xoha.instruction_dept )
      -- �p�����[�^�����D�o�Ɍ`��
      AND   xoha.order_type_id    = NVL( gr_param.deliver_type_id, xoha.order_type_id )
      -- �p�����[�^�����D�˗��m��
      AND   xoha.request_no       = NVL( gr_param.request_no, xoha.request_no )
-- add start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
      AND   xoha.deliver_from     = NVL( gr_param.deliver_from, xoha.deliver_from )
-- add end ver1.1
--
      -- 2008/11/13 �����w�E#603 Del Start ---------------------------------------------
      ---- �p�����[�^�����D�o�ɓ�FromTo
      --AND   xoha.schedule_ship_date BETWEEN gr_param.date_from
      --                              AND     NVL( gr_param.date_to, xoha.schedule_ship_date )
      -- 2008/11/13 �����w�E#603 Del End ------------------------------------------------
      -- 2008/11/13 �����w�E#603 Add Start ---------------------------------------------
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xoha.shipped_date BETWEEN gr_param.date_from
                                    AND     NVL( gr_param.date_to, xoha.shipped_date )
      -- 2008/11/13 �����w�E#603 Add End ------------------------------------------------
--
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xoha.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xoha.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xoha.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 �����w�E#461 Del End ---------------------------------------
--
      -- 2008/10/31 �����w�E#461 Add Start -------------------------------------
      AND   NVL(xoha.career_id,gn_nvl_null_num)  =   xcv.party_id(+)
      AND   xoha.shipped_date             >=   xcv.start_date_active(+)
      AND   xoha.shipped_date             <=   xcv.end_date_active(+)
      -- 2008/10/31 �����w�E#461 Add End ---------------------------------------
    ;
    */
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Del End
    ---------------------------------------------------------------------------------------------------------------------
--
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Add Start
    ---------------------------------------------------------------------------------------------------------------------
    -- �w���E���уf�[�^�擾�J�[�\��
    CURSOR cu_main
    IS
    --***************************************
    --* �w��
    --***************************************
    SELECT trn.location_code             AS location_code         -- �o�ɑq�ɃR�[�h
          ,trn.location_name             AS location_name         -- �o�ɑq�ɖ���
          ,trn.ship_date                 AS ship_date             -- �o�ɓ�
          ,trn.arvl_date                 AS arvl_date             -- ���ɓ�
          ,trn.head_sales_branch         AS head_sales_branch     -- ���������F�Ǌ����_
          ,trn.deliver_id                AS deliver_id            -- ���������F�z����
          ,trn.career_id                 AS career_id             -- ���������F�^���Ǝ�
          ,trn.ship_method_code          AS ship_method_code      -- ���������F�z���敪
          ,trn.order_type                AS order_type            -- �Ɩ���ʁi�R�[�h�j
          ,trn.delivery_no               AS delivery_no           -- �z���m��
          ,trn.request_no                AS request_no            -- �˗��m��
          ,trn.order_line_id             AS order_line_id         -- ���������F���ׂh�c
          ,trn.item_id                   AS item_id               -- ���������F�i�ڂh�c
          ,trn.item_code                 AS item_code             -- �i�ڃR�[�h
          ,trn.item_name                 AS item_name             -- �i�ږ���
          ,trn.lot_ctl                   AS lot_ctl               -- ���������F���b�g�g�p
          ,trn.quant_r                   AS quant_r               -- �˗���
          ,trn.quant_i                   AS quant_i               -- ���ɐ�
          ,trn.quant_o                   AS quant_o               -- �o�ɐ�
          ,trn.status                    AS status                -- �w�b�_�X�e�[�^�X
          ,trn.lot_id                    AS lot_id                -- ���b�gID
          ,trn.conv_unit                 AS conv_unit             -- ���o�Ɋ��Z�P��
          ,trn.num_of_cases              AS num_of_cases          -- �P�[�X����
          ,trn.freight_charge_code       AS freight_charge_code   -- �^���敪
          ,trn.complusion_output_kbn     AS complusion_output_kbn -- �����o�͋敪
          ,trn.no_instr_actual           AS no_instr_actual       -- �w���Ȃ�����:'Y' �w���������:'N'
          ,trn.lot_inst_cnt              AS lot_inst_cnt          -- �w�����b�g�̌���
          ,ROW_NUMBER() OVER(PARTITION BY trn.request_no,trn.item_code order by trn.lot_id) AS row_num -- �˗�No�E�i�ڂ��ƂɃ��b�gID������1����̔�
      FROM (
        SELECT /*+ leading (xoha xola otta xmld iimb gic1 mcb1 gic2 mcb2) use_nl(xoha xola otta xmld iimb gic1 mcb1 gic2 mcb2) */
             xoha.deliver_from             AS location_code      -- �o�ɑq�ɃR�[�h
            ,SUBSTRB(xil.description,1,20) AS location_name      -- �o�ɑq�ɖ���
            ,xoha.schedule_ship_date      AS ship_date          -- �o�ɓ�
            ,xoha.schedule_arrival_date   AS arvl_date          -- ���ɓ�
            ,xoha.head_sales_branch       AS head_sales_branch  -- ���������F�Ǌ����_
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN xoha.deliver_to_id
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                          AS deliver_id         -- ���������F�z����
            ,xoha.career_id               AS career_id          -- ���������F�^���Ǝ�
            ,xoha.shipping_method_code    AS ship_method_code   -- ���������F�z���敪
            ,otta.attribute1              AS order_type         -- �Ɩ���ʁi�R�[�h�j
            ,xoha.delivery_no             AS delivery_no        -- �z���m��
            ,xoha.request_no              AS request_no         -- �˗��m��
            ,xola.order_line_id           AS order_line_id      -- ���������F���ׂh�c
            ,iimb.item_id                 AS item_id            -- ���������F�i�ڂh�c
            ,iimb.item_no                 AS item_code          -- �i�ڃR�[�h
            ,ximb.item_short_name         AS item_name          -- �i�ږ���
            ,iimb.lot_ctl                 AS lot_ctl            -- ���������F���b�g�g�p
            ,NVL(xola.quantity, 0)         AS quant_r            -- �˗���
            ,NVL(xola.ship_to_quantity, 0) AS quant_i            -- ���ɐ�
            ,NVL(xola.shipped_quantity, 0) AS quant_o            -- �o�ɐ�
            ,xoha.req_status              AS status              -- �w�b�_�X�e�[�^�X
            ,xmld.lot_id                  AS lot_id              -- ���b�gID
            ,iimb.attribute24             AS conv_unit           -- ���o�Ɋ��Z�P��
            ,TO_NUMBER(iimb.attribute11)  AS num_of_cases        -- �P�[�X����
            ,xoha.freight_charge_class    AS freight_charge_code -- �^���敪
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,COUNT(xmld.lot_id)           AS lot_inst_cnt        -- �w�����b�g�̌���
        FROM
           xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
          ,xxinv_mov_lot_details      xmld
          ,ic_item_mst_b              iimb
          ,xxcmn_item_mst_b           ximb
          ,gmi_item_categories        gic1
          ,mtl_categories_b           mcb1
          ,gmi_item_categories        gic2
          ,mtl_categories_b           mcb2
          ,xxcmn_item_locations2_v    xil
          ,xxcmn_carriers2_v          xcv       -- �^���Ǝҏ��VIEW2
        WHERE  xoha.schedule_ship_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xoha.schedule_ship_date)   -- �p�����[�^�����D�o�ɓ�FromTo
        AND   xoha.req_status IN( gc_req_status_s_cmpb    -- �o�ׁF���ς�
                               ,gc_req_status_s_cmpc    -- �o�ׁF�o�׎��ьv���
                               ,gc_req_status_p_cmpb    -- �x���F��̍�
                               ,gc_req_status_p_cmpc )  -- �x���F�o�׎��ьv���
        AND    xoha.latest_external_flag = gc_yn_div_y
        AND    xoha.instruction_dept     = NVL(gr_param.dept_code, xoha.instruction_dept)    -- �p�����[�^�����D�w������
        AND    xoha.order_type_id        = NVL(gr_param.deliver_type_id, xoha.order_type_id) -- �p�����[�^�����D�o�Ɍ`��
        AND    xoha.request_no           = NVL(gr_param.request_no,xoha.request_no)          -- �p�����[�^�����D�˗��m��
        AND    xoha.deliver_from         = NVL(gr_param.deliver_from,xoha.deliver_from)      -- �p�����[�^�����D�o�Ɍ�
        AND    xoha.order_header_id       = xola.order_header_id
        AND    NVL(xola.delete_flag,gc_yn_div_n) = gc_yn_div_n
        AND    xoha.order_type_id        = otta.transaction_type_id
        AND    otta.order_category_code  = gc_order_cat_o
        AND    otta.attribute1          IN (gc_sp_class_ship     -- �o�׈˗�
                                           ,gc_sp_class_prov)    -- �x���˗�
        AND    xmld.mov_line_id(+)       = xola.order_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code IN (gc_doc_type_ship
                                            ,gc_doc_type_prov))
               )
        AND    xola.shipping_item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- �p�����[�^�����D���i�敪
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- �p�����[�^�����D�i�ڋ敪
        AND    xoha.deliver_from_id       = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
        AND    (
                  ((gr_param.block_01  IS NULL) AND   -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
                   (gr_param.block_02  IS NULL) AND
                   (gr_param.block_03  IS NULL)
                  )
              OR  (xil.distribution_block     IN(gr_param.block_01   -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
                                                 ,gr_param.block_02
                                                 ,gr_param.block_03)
                  )
               )
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- �p�����[�^�����D�I�����C���敪
        AND    NVL(xoha.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xoha.schedule_ship_date >= xcv.start_date_active(+)
        AND    xoha.schedule_ship_date <= xcv.end_date_active(+)
--
        GROUP BY xoha.deliver_from
                ,SUBSTRB(xil.description,1,20)
                ,xoha.schedule_ship_date
                ,xoha.schedule_arrival_date
                ,xoha.head_sales_branch
                ,CASE otta.attribute1
                   WHEN gc_sp_class_ship THEN xoha.deliver_to_id
                   WHEN gc_sp_class_prov THEN xoha.vendor_site_id
                 END
                ,xoha.career_id
                ,xoha.shipping_method_code
                ,otta.attribute1
                ,xoha.delivery_no
                ,xoha.request_no
                ,xola.order_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xola.quantity,0)
                ,NVL(xola.ship_to_quantity, 0)
                ,NVL(xola.shipped_quantity,0)
                ,xoha.req_status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xoha.freight_charge_class
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n)
--
        UNION
        --***************************************
        --* ����
        --***************************************
        SELECT /*+ leading (xoha xola otta iimb gic1 mcb1 gic2 mcb2) use_nl(xoha xola otta iimb gic1 mcb1 gic2 mcb2) */
             xoha.deliver_from                  AS location_code     -- �o�ɑq�ɃR�[�h
            ,SUBSTRB(xil.description,1,20)      AS location_name     -- �o�ɑq�ɖ���
            ,NVL( xoha.shipped_date
                 ,xoha.schedule_ship_date    )  AS ship_date         -- �o�ɓ�
            ,NVL( xoha.arrival_date
                 ,xoha.schedule_arrival_date )  AS arvl_date         -- ���ɓ�
            ,xoha.head_sales_branch             AS head_sales_branch -- ���������F�Ǌ����_
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN NVL( xoha.result_deliver_to_id, xoha.deliver_to_id )
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                                AS deliver_id       -- ���������F�z����
            ,NVL( xoha.result_freight_carrier_id
                 ,xoha.career_id )              AS career_id        -- ���������F�^���Ǝ�
            ,NVL( xoha.result_shipping_method_code
                 ,xoha.shipping_method_code )   AS ship_method_code -- ���������F�z���敪
            ,otta.attribute1                    AS order_type       -- �Ɩ���ʁi�R�[�h�j
            ,xoha.delivery_no                   AS delivery_no      -- �z���m��
            ,xoha.request_no                    AS request_no       -- �˗��m��
            ,xola.order_line_id                 AS order_line_id    -- ���������F���ׂh�c
            ,iimb.item_id                       AS item_id          -- ���������F�i�ڂh�c
            ,iimb.item_no                       AS item_code        -- �i�ڃR�[�h
            ,ximb.item_short_name               AS item_name        -- �i�ږ���
            ,iimb.lot_ctl                       AS lot_ctl          -- ���������F���b�g�g�p
            ,NVL( xola.quantity, 0 )            AS quant_r          -- �˗���
            ,NVL( xola.ship_to_quantity , 0 )   AS quant_i          -- ���ɐ�
            ,NVL( xola.shipped_quantity , 0 )   AS quant_o          -- �o�ɐ�
            ,xoha.req_status                    AS status           -- �w�b�_�X�e�[�^�X
            ,xmld.lot_id                        AS lot_id           -- ���b�gID
            ,iimb.attribute24                   AS conv_unit        -- ���o�Ɋ��Z�P��
            ,TO_NUMBER(iimb.attribute11)        AS num_of_cases     -- �P�[�X����
            ,xoha.freight_charge_class          AS freight_charge_code   -- �^���敪
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,COUNT(xmld.lot_id)                 AS lot_inst_cnt        -- �w�����b�g�̌���
        FROM
           xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
          ,oe_transaction_types_all   otta      -- �󒍃^�C�v
          ,xxinv_mov_lot_details      xmld
          ,ic_item_mst_b              iimb
          ,xxcmn_item_mst_b           ximb
          ,gmi_item_categories        gic1
          ,mtl_categories_b           mcb1
          ,gmi_item_categories        gic2
          ,mtl_categories_b           mcb2
          ,xxcmn_item_locations2_v    xil
          ,xxcmn_carriers2_v          xcv       -- �^���Ǝҏ��VIEW2
        WHERE  xoha.shipped_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xoha.shipped_date)   -- �p�����[�^�����D�o�ɓ�FromTo
        AND   xoha.req_status IN( gc_req_status_s_cmpb    -- �o�ׁF���ς�
                               ,gc_req_status_s_cmpc    -- �o�ׁF�o�׎��ьv���
                               ,gc_req_status_p_cmpb    -- �x���F��̍�
                               ,gc_req_status_p_cmpc )  -- �x���F�o�׎��ьv���
        AND    xoha.latest_external_flag = gc_yn_div_y
        AND    xoha.instruction_dept     = NVL(gr_param.dept_code, xoha.instruction_dept)    -- �p�����[�^�����D�w������
        AND    xoha.order_type_id        = NVL(gr_param.deliver_type_id, xoha.order_type_id) -- �p�����[�^�����D�o�Ɍ`��
        AND    xoha.request_no           = NVL(gr_param.request_no,xoha.request_no)          -- �p�����[�^�����D�˗��m��
        AND    xoha.deliver_from         = NVL(gr_param.deliver_from,xoha.deliver_from)      -- �p�����[�^�����D�o�Ɍ�
        AND    xoha.order_header_id       = xola.order_header_id
        AND    NVL(xola.delete_flag,gc_yn_div_n) = gc_yn_div_n
        AND    xoha.order_type_id        = otta.transaction_type_id
        AND    otta.order_category_code  = gc_order_cat_o
        AND    otta.attribute1          IN (gc_sp_class_ship     -- �o�׈˗�
                                           ,gc_sp_class_prov)    -- �x���˗�
        AND    xmld.mov_line_id(+)       = xola.order_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code IN (gc_doc_type_ship
                                            ,gc_doc_type_prov))
               )
        AND    xola.shipping_item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- �p�����[�^�����D���i�敪
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- �p�����[�^�����D�i�ڋ敪
        AND    xoha.deliver_from_id       = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
        AND    (
                  ((gr_param.block_01  IS NULL) AND   -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
                   (gr_param.block_02  IS NULL) AND
                   (gr_param.block_03  IS NULL)
                  )
              OR  (xil.distribution_block     IN(gr_param.block_01   -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
                                                 ,gr_param.block_02
                                                 ,gr_param.block_03)
                  )
               )
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- �p�����[�^�����D�I�����C���敪
        AND    NVL(xoha.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xoha.shipped_date >= xcv.start_date_active(+)
        AND    xoha.shipped_date <= xcv.end_date_active(+)
--
        GROUP BY xoha.deliver_from
                ,SUBSTRB(xil.description,1,20)
                ,NVL(xoha.shipped_date, xoha.schedule_ship_date)
                ,NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                ,xoha.head_sales_branch
                ,CASE otta.attribute1
                   WHEN gc_sp_class_ship THEN NVL( xoha.result_deliver_to_id, xoha.deliver_to_id )
                   WHEN gc_sp_class_prov THEN xoha.vendor_site_id
                 END
                ,NVL(xoha.result_freight_carrier_id, xoha.career_id )
                ,NVL(xoha.result_shipping_method_code, xoha.shipping_method_code)
                ,otta.attribute1
                ,xoha.delivery_no
                ,xoha.request_no
                ,xola.order_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xola.quantity,0)
                ,NVL(xola.ship_to_quantity, 0)
                ,NVL(xola.shipped_quantity,0)
                ,xoha.req_status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xoha.freight_charge_class
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n)
      ) trn
    ;
--
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Add End
    ---------------------------------------------------------------------------------------------------------------------
--
    -- �ۗ��f�[�^�擾
    CURSOR cu_reserv
    IS
      SELECT xil.segment1                     AS location_code    -- �o�ɑq�ɃR�[�h
            --,xil.description                  AS location_name    -- �o�ɑq�ɖ��� 2008/10/10 �����e�X�g��Q#338 Del
            ,SUBSTRB(xil.description,1,20)    AS location_name    -- �o�ɑq�ɖ���   2008/10/10 �����e�X�g��Q#338 Add
            ,xshi.shipped_date                AS ship_date        -- �o�ɓ�
            ,xshi.arrival_date                AS arvl_date        -- ���ɓ�
      -- 2008/12/06 Modify Start T.Miyata #516 �˗�No�ɕR�t���Ǌ����_������Ε\������B�z�����\������B
-- mod start ver1.1
            , xshi.head_sales_branch            AS head_sales_branch -- ���������F�Ǌ����_
--            ,NULL                             AS po_no            -- ���������F�Ǌ����_
-- mod end ver1.1
--            ,xshi.party_site_code             AS deliver_id       -- ���������F�z����
            ,xpsv.party_site_id               AS deliver_id       -- �z����
      -- 2008/12/06 Modify End T.Miyata #51
            ,xshi.freight_carrier_code        AS career_id        -- ���������F�^���Ǝ�
            ,xshi.shipping_method_code        AS ship_method_code -- ���������F�z���敪
            ,xshi.eos_data_type               AS order_type       -- �Ɩ���ʁi�R�[�h�j
            ,xshi.delivery_no                 AS delivery_no      -- �z���m��
            ,xshi.order_source_ref            AS request_no       -- �˗��m��
            ,xsli.line_id                     AS order_line_id    -- ���������F���ׂh�c
            ,ximv.item_id                     AS item_id          -- ���������F�i�ڂh�c
            ,ximv.item_no                     AS item_code        -- �i�ڃR�[�h
            ,ximv.item_short_name             AS item_name        -- �i�ږ���
            ,ximv.lot_ctl                     AS lot_ctl          -- ���������F���b�g�g�p
            ,xsli.orderd_quantity             AS quant_r          -- �˗���
            ,xsli.ship_to_quantity            AS quant_i          -- ���ɐ�
            ,xsli.shiped_quantity             AS quant_o          -- �o�ɐ�
-- 2008/07/24 A.Shiina v1.7 ADD Start
            ,xsli.detailed_quantity           AS quant_d          -- ���󐔗�(�C���^�t�F�[�X�p)
-- 2008/07/24 A.Shiina v1.7 ADD End
            ,NULL                             AS status           -- �w�b�_�X�e�[�^�X
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xshi.filler14                    AS freight_charge_code   -- �^���敪
            --,xcv.complusion_output_code       AS complusion_output_kbn -- �����o�͋敪    -- 2008/10/31 �����w�E#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪   -- 2008/10/31 �����w�E#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
      FROM xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
          ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
          ,xxcmn_item_locations2_v    xil       -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v          ximv      -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v   xicv      -- �n�o�l�i�ڃJ�e�S���������VIEW4
          -- 2008/12/06 Modify Start T.Miyata #516 �˗�No�ɕR�t���Ǌ����_������Ε\������B�z����A���ɐ�̕\��
          ,xxcmn_party_sites_v        xpsv      -- �ڋq�T�C�g�r���[
          -- 2008/12/06 Modify End T.Miyata #516
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- �^���Ǝҏ��VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = gr_param.item_div
      AND   ximv.item_id                = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xsli.orderd_item_code       = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- �h�e����
      ----------------------------------------------------------------------------------------------
      AND   xsli.reserved_status  = gc_reserved_status_y        -- �ۗ��X�e�[�^�X = �ۗ�
      AND   xshi.header_id        = xsli.header_id
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
-- del start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
-- 2008/07/24 A.Shiina v1.7 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xshi.location_code    = xil.segment1
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- �h�e�w�b�_
      ----------------------------------------------------------------------------------------------
      AND   xshi.eos_data_type  IN( gc_eos_type_rpt_ship_k      -- ���_�o�׊m���
                                   ,gc_eos_type_rpt_ship_y )    -- �L���o�ו�
      -- �p�����[�^�����D�˗��m��
      AND   xshi.order_source_ref = NVL( gr_param.request_no, xshi.order_source_ref )
-- add start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
      AND xshi.location_code    = NVL( gr_param.deliver_from, xshi.location_code )
      -- �p�����[�^�����D�w������
      AND xshi.report_post_code = NVL( gr_param.dept_code, xshi.report_post_code )
-- add end ver1.1
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xshi.shipped_date     BETWEEN gr_param.date_from
                                  AND     NVL( gr_param.date_to, xshi.shipped_date )
--
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xshi.freight_carrier_code         =   xcv.party_number
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xshi.shipped_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xshi.shipped_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
--
      -- 2008/10/31 �����w�E#461 Add Start -------------------------------------
      AND   NVL(xshi.freight_carrier_code,gv_nvl_null_char)  =   xcv.party_number(+)
      AND   xshi.shipped_date                               >=   xcv.start_date_active(+)
      AND   xshi.shipped_date                               <=   xcv.end_date_active(+)
      -- 2008/10/31 �����w�E#461 Add End ---------------------------------------
      -- 2008/12/06 T.Miyata Modify Start #516 �z����
      AND   xshi.party_site_code  = xpsv.party_site_number(+)
      -- 2008/12/06 T.Miyata Modify End #516
--
    ;
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �w�����уf�[�^���o�E�o�^����
    -- ====================================================
    -- �o�͋敪���u�ۗ��v�ȊO�̏ꍇ
    IF (  ( gr_param.output_type IS NULL )
       OR ( gr_param.output_type <> gc_output_type_rsrv ) ) THEN
      <<main_loop>>
      FOR re_main IN cu_main LOOP
        --------------------------------------------------
        -- ���o�f�[�^�i�[
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- �o�ɑq�ɃR�[�h
        lr_get_data.location_name    := re_main.location_name ;     -- �o�ɑq�ɖ���
        lr_get_data.ship_date        := re_main.ship_date ;         -- �o�ɓ�
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- ���ɓ�
-- mod start ver1.1
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- ���������F�Ǌ����_
--        lr_get_data.po_no            := re_main.po_no ;             -- ���������F�Ǌ����_
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- ���������F�z����
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- �^���敪
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- �����o�͋敪
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- ���������F�^���Ǝ�
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- ���������F�z���敪
        lr_get_data.order_type       := re_main.order_type ;        -- �Ɩ���ʁi�R�[�h�j
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- �z���m��
        lr_get_data.request_no       := re_main.request_no ;        -- �˗��m��
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- ���������F���ׂh�c
        lr_get_data.item_id          := re_main.item_id ;           -- ���������F�i�ڂh�c
        lr_get_data.item_code        := re_main.item_code ;         -- �i�ڃR�[�h
        lr_get_data.item_name        := re_main.item_name ;         -- �i�ږ���
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- ���������F���b�g�g�p
        lr_get_data.quant_r          := re_main.quant_r ;           -- �˗����i���b�g�Ǘ��O�j
        lr_get_data.quant_i          := re_main.quant_i ;           -- ���ɐ��i���b�g�Ǘ��O�j
        lr_get_data.quant_o          := re_main.quant_o ;           -- �o�ɐ��i���b�g�Ǘ��O�j
        lr_get_data.status           := re_main.status ;            -- �󒍃w�b�_�X�e�[�^�X
-- add start ver1.2
        lr_get_data.lot_id           := re_main.lot_id ;            -- ���b�gID
        lr_get_data.conv_unit        := re_main.conv_unit ;         -- ���o�Ɋ��Z�P��
        lr_get_data.num_of_cases     := re_main.num_of_cases ;      -- �P�[�X����
-- add end ver1.2
-- 2008/11/17 �����w�E#651 Add Start ---------------------------------------
        lr_get_data.no_instr_actual  := re_main.no_instr_actual ;
        lr_get_data.lot_inst_cnt     := re_main.lot_inst_cnt ;
        lr_get_data.row_num          := re_main.row_num ;
-- 2008/11/17 �����w�E#651 Add End -----------------------------------------
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^�f�[�^�ݒ�
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
    END IF ;
--
    -- ====================================================
    -- �ۗ��f�[�^���o�E�o�^����
    -- ====================================================
    -- �o�͋敪���u�ۗ��v�̏ꍇ
    IF ( gr_param.output_type IS NULL )
    OR ( gr_param.output_type = gc_output_type_rsrv ) THEN
      <<reserv_loop>>
      FOR re_main IN cu_reserv LOOP
        --------------------------------------------------
        -- ���o�f�[�^�i�[
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- �o�ɑq�ɃR�[�h
        lr_get_data.location_name    := re_main.location_name ;     -- �o�ɑq�ɖ���
        lr_get_data.ship_date        := re_main.ship_date ;         -- �o�ɓ�
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- ���ɓ�
-- mod start ver1.1
--        lr_get_data.po_no            := re_main.po_no ;             -- ���������F�Ǌ����_
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- ���������F�Ǌ����_
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- ���������F�z����
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- �^���敪
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- �����o�͋敪
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- ���������F�^���Ǝ�
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- ���������F�z���敪
        lr_get_data.order_type       := re_main.order_type ;        -- �Ɩ���ʁi�R�[�h�j
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- �z���m��
        lr_get_data.request_no       := re_main.request_no ;        -- �˗��m��
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- ���������F���ׂh�c
        lr_get_data.item_id          := re_main.item_id ;           -- ���������F�i�ڂh�c
        lr_get_data.item_code        := re_main.item_code ;         -- �i�ڃR�[�h
        lr_get_data.item_name        := re_main.item_name ;         -- �i�ږ���
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- ���������F���b�g�g�p
        lr_get_data.quant_r          := re_main.quant_r ;           -- �˗����i���b�g�Ǘ��O�j
        lr_get_data.quant_i          := re_main.quant_i ;           -- ���ɐ��i���b�g�Ǘ��O�j
        lr_get_data.quant_o          := re_main.quant_o ;           -- �o�ɐ��i���b�g�Ǘ��O�j
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
        lr_get_data.quant_d          := re_main.quant_d  ;          -- ���󐔗�(�C���^�t�F�[�X�p)
-- 2008/07/24 A.Shiina v1.7 UPDATE End
        lr_get_data.status           := re_main.status ;            -- �w�b�_�X�e�[�^�X
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^�f�[�^�ݒ�
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
    END IF ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
-- add start ver1.1
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
-- add end   ver1.1
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
  END prc_create_ship_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_move_data
   * Description      : �ړ��f�[�^���o����
   ************************************************************************************************/
  PROCEDURE prc_create_move_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_move_data' ; -- �v���O������
--
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')); -- 2008/12/03 �{�ԏ�Q#333 Add
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')); -- 2008/12/03 �{�ԏ�Q#333 Add
--
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    lr_get_data       rec_get_data ;        -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
    lr_temp_tab       rec_temp_tab_data ;   -- ���ԃe�[�u���o�^�p���R�[�h�ϐ�
--
    -- ==================================================
    -- �J  �[  �\  ��  ��  ��
    -- ==================================================
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Del Start
    ---------------------------------------------------------------------------------------------------------------------
    /*
    -- �w���E���уf�[�^�擾�J�[�\��
    CURSOR cu_main
    IS
    --***************************************
    --* �w��
    --***************************************
      SELECT xil.segment1                 AS location_code    -- �o�ɑq�ɃR�[�h
            --,xil.description              AS location_name    -- �o�ɑq�ɖ��� 2008/10/10 �����e�X�g��Q#338 Del
            ,SUBSTRB(xil.description,1,20) AS location_name    -- �o�ɑq�ɖ���  2008/10/10 �����e�X�g��Q#338 Add
            ,xmrih.schedule_ship_date     AS ship_date        -- �o�ɓ�
            ,xmrih.schedule_arrival_date  AS arvl_date        -- ���ɓ�
-- mod start ver1.1
--            ,NULL                         AS po_no            -- ���������F�Ǌ����_
            ,NULL                         AS head_sales_branch -- ���������F�Ǌ����_
-- mod end ver1.1
            ,xmrih.ship_to_locat_id       AS deliver_id       -- ���������F���ɐ�
            ,xmrih.career_id              AS career_id        -- ���������F�^���Ǝ�
            ,xmrih.shipping_method_code   AS ship_method_code -- ���������F�z���敪
            ,gc_sp_class_move             AS order_type       -- �Ɩ���ʁi�R�[�h�j
            ,xmrih.delivery_no            AS delivery_no      -- �z���m��
            ,xmrih.mov_num                AS request_no       -- �˗��m��
            ,xmril.mov_line_id            AS order_line_id    -- ���������F���ׂh�c
            ,ximv.item_id                 AS item_id          -- ���������F�i�ڂh�c
            ,ximv.item_no                 AS item_code        -- �i�ڃR�[�h
            ,ximv.item_short_name         AS item_name        -- �i�ږ���
            ,ximv.lot_ctl                 AS lot_ctl          -- ���������F���b�g�g�p
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r    -- �˗����i���b�g�Ǘ��O�j
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i    -- ���ɐ��i���b�g�Ǘ��O�j
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o    -- �o�ɐ��i���b�g�Ǘ��O�j
            ,xmrih.status                 AS status           -- �w�b�_�X�e�[�^�X
-- add start ver1.1
            ,ximv.conv_unit               AS conv_unit             -- ���o�Ɋ��Z�P��
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- �P�[�X����
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- �P�[�X����
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- add end ver1.1
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ���b�gID
-- add end ver1.2
-- add start ver1.3
            ,xicv.prod_class_code         AS prod_class_code       -- ���i�敪
-- add end ver1.3
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xmrih.freight_charge_class   AS freight_charge_code   -- �^���敪
            --,xcv.complusion_output_code   AS complusion_output_kbn -- �����o�͋敪       -- 2008/10/31 �����w�E#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪  -- 2008/10/31 �����w�E#461 Add
-- 2008/11/17 �����w�E#651 Add Start ------------------------------------------------------
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code = gc_doc_type_move
                AND xmld2.record_type_code = gc_rec_type_inst  -- �w�����b�g
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- �w�����b�g�̌���
            ,ROW_NUMBER() OVER (PARTITION BY xmrih.mov_num
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- �˗�No�E�i�ڂ��ƂɃ��b�gID������1����̔�
-- 2008/11/17 �����w�E#651 Add End --------------------------------------------------------
-- 2008/07/07 A.Shiina v1.5 ADD End
      FROM xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril   -- �ړ��˗�/�w�����׃A�h�I��
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld 
            WHERE  xmld.document_type_code = gc_doc_type_move
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld    -- �ړ����b�g�ڍ׃A�h�I��
-- add end ver1.2
          ,xxcmn_item_locations2_v        xil     -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v              ximv    -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v       xicv    -- �n�o�l�i�ڃJ�e�S���������VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v              xcv     -- �^���Ǝҏ��VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = gr_param.item_div
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xmril.item_id           = ximv.item_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w�����׃A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
      AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xmril.mov_line_id
      AND   xmld.mov_line_id(+)        = xmril.mov_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D�o�Ɍ�
-- mod start ver1.1
--      AND   xil.segment1            = NVL( gr_param.deliver_from, xil.segment1 )
      AND   xil.segment1            = xmrih.shipped_locat_code
-- mod end ver1.1
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
-- 2008/07/24 A.Shiina v1.7 ADD Start
--      AND   (  gr_param.block_01   IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02   IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03   IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xmrih.shipped_locat_id = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w���w�b�_�A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   xmrih.status              IN( gc_mov_status_cmp       -- �˗���
                                         ,gc_mov_status_adj       -- ������
                                         ,gc_mov_status_del       -- �o�ɕ񍐗L
                                         ,gc_mov_status_stc       -- ���ɕ񍐗L
                                         ,gc_mov_status_dsr )     -- ���o�ɕ񍐗L
      AND   xmrih.mov_type              = gc_mov_type_y
      -- �p�����[�^�����D�w������
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      -- �p�����[�^�����D�˗��m��
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
-- add start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
      AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )
-- add end ver1.1
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
--
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xmrih.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xmrih.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xmrih.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
--
      -- 2008/10/31 �����w�E#461 Add Start -------------------------------------
      AND   NVL(xmrih.career_id,gn_nvl_null_num)  =   xcv.party_id(+)
      AND   xmrih.schedule_ship_date   >=   xcv.start_date_active(+)
      AND   xmrih.schedule_ship_date   <=   xcv.end_date_active(+)
      -- 2008/10/31 �����w�E#461 Add End ---------------------------------------
--
      UNION
      --***************************************
      --* ����
      --***************************************
      SELECT xil.segment1                       AS location_code    -- �o�ɑq�ɃR�[�h
            --,xil.description                    AS location_name    -- �o�ɑq�ɖ��� 2008/10/10 �����e�X�g��Q#338 Del
            ,SUBSTRB(xil.description,1,20)      AS location_name    -- �o�ɑq�ɖ���   2008/10/10 �����e�X�g��Q#338 Add
            ,NVL( xmrih.actual_ship_date
                 ,xmrih.schedule_ship_date )    AS ship_date        -- �o�ɓ�
            ,NVL( xmrih.actual_arrival_date
                 ,xmrih.schedule_arrival_date ) AS arvl_date        -- ���ɓ�
-- mod start ver1.1
--            ,NULL                               AS po_no            -- ���������F�Ǌ����_
            ,NULL                               AS head_sales_branch -- ���������F�Ǌ����_
-- mod end ver1.1
            ,xmrih.ship_to_locat_id             AS deliver_id       -- ���������F���ɐ�
            ,NVL( xmrih.actual_career_id
                 ,xmrih.career_id )             AS career_id        -- ���������F�^���Ǝ�
            ,NVL( xmrih.actual_shipping_method_code
                 ,xmrih.shipping_method_code )  AS ship_method_code -- ���������F�z���敪
            ,gc_sp_class_move                   AS order_type       -- �Ɩ���ʁi�R�[�h�j
            ,xmrih.delivery_no                  AS delivery_no      -- �z���m��
            ,xmrih.mov_num                      AS request_no       -- �˗��m��
            ,xmril.mov_line_id                  AS order_line_id    -- ���������F���ׂh�c
            ,ximv.item_id                       AS item_id          -- ���������F�i�ڂh�c
            ,ximv.item_no                       AS item_code        -- �i�ڃR�[�h
            ,ximv.item_short_name               AS item_name        -- �i�ږ���
            ,ximv.lot_ctl                       AS lot_ctl          -- ���������F���b�g�g�p
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r          -- �˗����i���b�g�Ǘ��O�j
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i          -- ���ɐ��i���b�g�Ǘ��O�j
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o          -- �o�ɐ��i���b�g�Ǘ��O�j
            ,xmrih.status                       AS status           -- �w�b�_�X�e�[�^�X
-- add start ver1.1
            ,ximv.conv_unit               AS conv_unit             -- ���o�Ɋ��Z�P��
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- �P�[�X����
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- �P�[�X����
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- add end ver1.1
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ���b�gID
-- add end ver1.2
-- add start ver1.3
            ,xicv.prod_class_code         AS prod_class_code       -- ���i�敪
-- add end ver1.3
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xmrih.freight_charge_class    AS freight_charge_code   -- �^���敪
            --,xcv.complusion_output_code    AS complusion_output_kbn -- �����o�͋敪      -- 2008/10/31 �����w�E#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪  -- 2008/10/31 �����w�E#461 Add
-- 2008/11/17 �����w�E#651 Add Start ------------------------------------------------------
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code = gc_doc_type_move
                AND xmld2.record_type_code = gc_rec_type_inst  -- �w�����b�g
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- �w�����b�g�̌���
            ,ROW_NUMBER() OVER (PARTITION BY xmrih.mov_num
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- �˗�No�E�i�ڂ��ƂɃ��b�gID������1����̔�
-- 2008/11/17 �����w�E#651 Add End --------------------------------------------------------
-- 2008/07/07 A.Shiina v1.5 ADD End
      FROM xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril   -- �ړ��˗�/�w�����׃A�h�I��
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld 
            WHERE  xmld.document_type_code = gc_doc_type_move
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld    -- �ړ����b�g�ڍ׃A�h�I��
-- add end ver1.2
          ,xxcmn_item_locations2_v        xil     -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v              ximv    -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v       xicv    -- �n�o�l�i�ڃJ�e�S���������VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v              xcv     -- �^���Ǝҏ��VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = NVL( gr_param.item_div, xicv.prod_class_code )
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xmril.item_id           = ximv.item_id
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w�����׃A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
      AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xmril.mov_line_id
      AND   xmld.mov_line_id(+)        = xmril.mov_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D�o�Ɍ�
-- mod start ver1.1
--      AND   xil.segment1            = NVL( gr_param.deliver_from, xil.segment1 )
      AND   xil.segment1            = xmrih.shipped_locat_code
-- mod end ver1.1
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
-- 2008/07/24 A.Shiina v1.7 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xmrih.shipped_locat_id = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- �ړ��˗��w���w�b�_�A�h�I��
      ----------------------------------------------------------------------------------------------
      AND   xmrih.status              IN( gc_mov_status_cmp       -- �˗���
                                         ,gc_mov_status_adj       -- ������
                                         ,gc_mov_status_del       -- �o�ɕ񍐗L
                                         ,gc_mov_status_stc       -- ���ɕ񍐗L
                                         ,gc_mov_status_dsr )     -- ���o�ɕ񍐗L
      AND   xmrih.mov_type              = gc_mov_type_y
      -- �p�����[�^�����D�w������
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      -- �p�����[�^�����D�˗��m��
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
-- add start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
      AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )
-- add end ver1.1
--
      -- 2008/11/13 �����w�E#603 Del Start ---------------------------------------------
      ---- �p�����[�^�����D�o�ɓ�FromTo
      --AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
      --                                  AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
      -- 2008/11/13 �����w�E#603 Del End -----------------------------------------------
      -- 2008/11/13 �����w�E#603 Add Start ---------------------------------------------
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xmrih.actual_ship_date    BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, xmrih.actual_ship_date )
      -- 2008/11/13 �����w�E#603 Add End -----------------------------------------------
--
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xmrih.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xmrih.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xmrih.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 �����w�E#461 Del End ---------------------------------------
--
      -- 2008/10/31 �����w�E#461 Add Start -------------------------------------
      AND   NVL(xmrih.career_id,gn_nvl_null_num) =   xcv.party_id(+)
      AND   xmrih.actual_ship_date    >=   xcv.start_date_active(+)
      AND   xmrih.actual_ship_date    <=   xcv.end_date_active(+)
      -- 2008/10/31 �����w�E#461 Add End ---------------------------------------
    ;
    */
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Del Start
    ---------------------------------------------------------------------------------------------------------------------
--
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Add Start
    ---------------------------------------------------------------------------------------------------------------------
    -- �w���E���уf�[�^�擾�J�[�\��
    CURSOR cu_main
    IS
    --***************************************
    --* �w��
    --***************************************
    SELECT trn.location_code             AS location_code         -- �o�ɑq�ɃR�[�h
          ,trn.location_name             AS location_name         -- �o�ɑq�ɖ���
          ,trn.ship_date                 AS ship_date             -- �o�ɓ�
          ,trn.arvl_date                 AS arvl_date             -- ���ɓ�
          ,trn.head_sales_branch         AS head_sales_branch     -- ���������F�Ǌ����_
          ,trn.deliver_id                AS deliver_id            -- ���������F�z����
          ,trn.career_id                 AS career_id             -- ���������F�^���Ǝ�
          ,trn.ship_method_code          AS ship_method_code      -- ���������F�z���敪
          ,trn.order_type                AS order_type            -- �Ɩ���ʁi�R�[�h�j
          ,trn.delivery_no               AS delivery_no           -- �z���m��
          ,trn.request_no                AS request_no            -- �˗��m��
          ,trn.order_line_id             AS order_line_id         -- ���������F���ׂh�c
          ,trn.item_id                   AS item_id               -- ���������F�i�ڂh�c
          ,trn.item_code                 AS item_code             -- �i�ڃR�[�h
          ,trn.item_name                 AS item_name             -- �i�ږ���
          ,trn.lot_ctl                   AS lot_ctl               -- ���������F���b�g�g�p
          ,trn.quant_r                   AS quant_r               -- �˗���
          ,trn.quant_i                   AS quant_i               -- ���ɐ�
          ,trn.quant_o                   AS quant_o               -- �o�ɐ�
          ,trn.status                    AS status                -- �w�b�_�X�e�[�^�X
          ,trn.lot_id                    AS lot_id                -- ���b�gID
          ,trn.conv_unit                 AS conv_unit             -- ���o�Ɋ��Z�P��
          ,trn.num_of_cases              AS num_of_cases          -- �P�[�X����
          ,trn.freight_charge_code       AS freight_charge_code   -- �^���敪
          ,trn.prod_class_code           AS prod_class_code       -- ���i�敪
          ,trn.complusion_output_kbn     AS complusion_output_kbn -- �����o�͋敪
          ,trn.no_instr_actual           AS no_instr_actual       -- �w���Ȃ�����:'Y' �w���������:'N'
          ,trn.lot_inst_cnt              AS lot_inst_cnt          -- �w�����b�g�̌���
          ,ROW_NUMBER() OVER(PARTITION BY trn.request_no,trn.item_code order by trn.lot_id) AS row_num -- �˗�No�E�i�ڂ��ƂɃ��b�gID������1����̔�
      FROM (
        SELECT /*+ leading (xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) */
             xil.segment1             AS location_code      -- �o�ɑq�ɃR�[�h
            ,SUBSTRB(xil.description,1,20) AS location_name      -- �o�ɑq�ɖ���
            ,xmrih.schedule_ship_date      AS ship_date          -- �o�ɓ�
            ,xmrih.schedule_arrival_date   AS arvl_date          -- ���ɓ�
            ,NULL                          AS head_sales_branch  -- ���������F�Ǌ����_
            ,xmrih.ship_to_locat_id       AS deliver_id       -- ���������F���ɐ�
            ,xmrih.career_id               AS career_id          -- ���������F�^���Ǝ�
            ,xmrih.shipping_method_code    AS ship_method_code   -- ���������F�z���敪
            ,gc_sp_class_move              AS order_type         -- �Ɩ���ʁi�R�[�h�j
            ,xmrih.delivery_no             AS delivery_no        -- �z���m��
            ,xmrih.mov_num                 AS request_no         -- �˗��m��
            ,xmril.mov_line_id           AS order_line_id      -- ���������F���ׂh�c
            ,iimb.item_id                 AS item_id            -- ���������F�i�ڂh�c
            ,iimb.item_no                 AS item_code          -- �i�ڃR�[�h
            ,ximb.item_short_name         AS item_name          -- �i�ږ���
            ,iimb.lot_ctl                 AS lot_ctl            -- ���������F���b�g�g�p
            ,NVL(xmril.instruct_qty, 0)         AS quant_r            -- �˗���
            ,NVL(xmril.ship_to_quantity, 0) AS quant_i            -- ���ɐ�
            ,NVL(xmril.shipped_quantity, 0) AS quant_o            -- �o�ɐ�
            ,xmrih.status                 AS status              -- �w�b�_�X�e�[�^�X
            ,xmld.lot_id                  AS lot_id              -- ���b�gID
            ,iimb.attribute24             AS conv_unit           -- ���o�Ɋ��Z�P��
            ,TO_NUMBER(iimb.attribute11)  AS num_of_cases        -- �P�[�X����
            ,xmrih.freight_charge_class    AS freight_charge_code -- �^���敪
            ,mcb1.segment1                 AS prod_class_code       -- ���i�敪
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,COUNT(xmld.lot_id)           AS lot_inst_cnt        -- �w�����b�g�̌���
        FROM
           xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril   -- �ړ��˗�/�w�����׃A�h�I��
          ,xxinv_mov_lot_details          xmld
          ,ic_item_mst_b                  iimb
          ,xxcmn_item_mst_b               ximb
          ,gmi_item_categories            gic1
          ,mtl_categories_b               mcb1
          ,gmi_item_categories            gic2
          ,mtl_categories_b               mcb2
          ,xxcmn_item_locations2_v        xil
          ,xxcmn_carriers2_v              xcv       -- �^���Ǝҏ��VIEW2
        WHERE  xmrih.schedule_ship_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xmrih.schedule_ship_date)   -- �p�����[�^�����D�o�ɓ�FromTo
        AND   xmrih.status              IN( gc_mov_status_cmp       -- �˗���
                                           ,gc_mov_status_adj       -- ������
                                           ,gc_mov_status_del       -- �o�ɕ񍐗L
                                           ,gc_mov_status_stc       -- ���ɕ񍐗L
                                           ,gc_mov_status_dsr )     -- ���o�ɕ񍐗L
        AND   xmrih.mov_type              = gc_mov_type_y
        AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )  -- �p�����[�^�����D�w������
        AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )  -- �p�����[�^�����D�˗��m��
        AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )  -- �p�����[�^�����D�o�Ɍ�
        AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
        AND   xmrih.mov_hdr_id          = xmril.mov_hdr_id
        AND   xmld.mov_line_id(+)        = xmril.mov_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code = gc_doc_type_move)
               )
        AND    xmril.item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- �p�����[�^�����D���i�敪
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- �p�����[�^�����D�i�ڋ敪
        AND    xmrih.shipped_locat_id    = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
        AND   (
                -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
                (
                  (gr_param.block_01 IS NULL)
                    AND  (gr_param.block_02 IS NULL)
                      AND  (gr_param.block_03 IS NULL)
                )
                OR
                -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
                (xil.distribution_block IN (gr_param.block_01,
                                            gr_param.block_02,
                                            gr_param.block_03)
                )
              )
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- �p�����[�^�����D�I�����C���敪
        AND    NVL(xmrih.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xmrih.schedule_ship_date >= xcv.start_date_active(+)
        AND    xmrih.schedule_ship_date <= xcv.end_date_active(+)
--
        GROUP BY xil.segment1
                ,SUBSTRB(xil.description,1,20)
                ,xmrih.schedule_ship_date
                ,xmrih.schedule_arrival_date
                ,NULL
                ,xmrih.ship_to_locat_id
                ,xmrih.career_id
                ,xmrih.shipping_method_code
                ,gc_sp_class_move
                ,xmrih.delivery_no
                ,xmrih.mov_num
                ,xmril.mov_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xmril.instruct_qty,0)
                ,NVL(xmril.ship_to_quantity, 0)
                ,NVL(xmril.shipped_quantity,0)
                ,xmrih.status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xmrih.freight_charge_class
                ,mcb1.segment1
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n)
--
        UNION
        --***************************************
        --* ����
        --***************************************
        SELECT /*+ leading (xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) */
             xil.segment1             AS location_code      -- �o�ɑq�ɃR�[�h
            ,SUBSTRB(xil.description,1,20) AS location_name      -- �o�ɑq�ɖ���
            ,NVL( xmrih.actual_ship_date
                 ,xmrih.schedule_ship_date )    AS ship_date        -- �o�ɓ�
            ,NVL( xmrih.actual_arrival_date
                 ,xmrih.schedule_arrival_date ) AS arvl_date        -- ���ɓ�
            ,NULL                               AS head_sales_branch -- ���������F�Ǌ����_
            ,xmrih.ship_to_locat_id       AS deliver_id       -- ���������F���ɐ�
            ,NVL( xmrih.actual_career_id
                 ,xmrih.career_id )             AS career_id        -- ���������F�^���Ǝ�
            ,NVL( xmrih.actual_shipping_method_code
                 ,xmrih.shipping_method_code )  AS ship_method_code -- ���������F�z���敪
            ,gc_sp_class_move              AS order_type         -- �Ɩ���ʁi�R�[�h�j
            ,xmrih.delivery_no             AS delivery_no        -- �z���m��
            ,xmrih.mov_num                 AS request_no         -- �˗��m��
            ,xmril.mov_line_id           AS order_line_id      -- ���������F���ׂh�c
            ,iimb.item_id                 AS item_id            -- ���������F�i�ڂh�c
            ,iimb.item_no                 AS item_code          -- �i�ڃR�[�h
            ,ximb.item_short_name         AS item_name          -- �i�ږ���
            ,iimb.lot_ctl                 AS lot_ctl            -- ���������F���b�g�g�p
            ,NVL(xmril.instruct_qty, 0)         AS quant_r            -- �˗���
            ,NVL(xmril.ship_to_quantity, 0) AS quant_i            -- ���ɐ�
            ,NVL(xmril.shipped_quantity, 0) AS quant_o            -- �o�ɐ�
            ,xmrih.status                 AS status              -- �w�b�_�X�e�[�^�X
            ,xmld.lot_id                  AS lot_id              -- ���b�gID
            ,iimb.attribute24             AS conv_unit           -- ���o�Ɋ��Z�P��
            ,TO_NUMBER(iimb.attribute11)  AS num_of_cases        -- �P�[�X����
            ,xmrih.freight_charge_class    AS freight_charge_code -- �^���敪
            ,mcb1.segment1                 AS prod_class_code       -- ���i�敪
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- �w���Ȃ�����:'Y' �w���������:'N'
            ,COUNT(xmld.lot_id)           AS lot_inst_cnt        -- �w�����b�g�̌���
        FROM
           xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_�A�h�I��
          ,xxinv_mov_req_instr_lines      xmril   -- �ړ��˗�/�w�����׃A�h�I��
          ,oe_transaction_types_all       otta      -- �󒍃^�C�v
          ,xxinv_mov_lot_details          xmld
          ,ic_item_mst_b                  iimb
          ,xxcmn_item_mst_b               ximb
          ,gmi_item_categories            gic1
          ,mtl_categories_b               mcb1
          ,gmi_item_categories            gic2
          ,mtl_categories_b               mcb2
          ,xxcmn_item_locations2_v        xil
          ,xxcmn_carriers2_v              xcv       -- �^���Ǝҏ��VIEW2
        WHERE  xmrih.actual_ship_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xmrih.actual_ship_date)   -- �p�����[�^�����D�o�ɓ�FromTo
        AND   xmrih.status              IN( gc_mov_status_cmp       -- �˗���
                                           ,gc_mov_status_adj       -- ������
                                           ,gc_mov_status_del       -- �o�ɕ񍐗L
                                           ,gc_mov_status_stc       -- ���ɕ񍐗L
                                           ,gc_mov_status_dsr )     -- ���o�ɕ񍐗L
        AND   xmrih.mov_type              = gc_mov_type_y
        AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )  -- �p�����[�^�����D�w������
        AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )  -- �p�����[�^�����D�˗��m��
        AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )  -- �p�����[�^�����D�o�Ɍ�
        AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- ���폜
        AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
        AND   xmld.mov_line_id(+)        = xmril.mov_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code = gc_doc_type_move)
               )
        AND    xmril.item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- �p�����[�^�����D���i�敪
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- �p�����[�^�����D�i�ڋ敪
        AND    xmrih.shipped_locat_id    = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
        AND   (
                -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
                (
                  (gr_param.block_01 IS NULL)
                    AND  (gr_param.block_02 IS NULL)
                      AND  (gr_param.block_03 IS NULL)
                )
                OR
                -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
                (xil.distribution_block IN (gr_param.block_01,
                                            gr_param.block_02,
                                            gr_param.block_03)
                )
              )
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- �p�����[�^�����D�I�����C���敪
        AND    NVL(xmrih.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xmrih.actual_ship_date >= xcv.start_date_active(+)
        AND    xmrih.actual_ship_date <= xcv.end_date_active(+)
--
        GROUP BY xil.segment1
                ,SUBSTRB(xil.description,1,20)
                ,NVL( xmrih.actual_ship_date,xmrih.schedule_ship_date )
                ,NVL( xmrih.actual_arrival_date,xmrih.schedule_arrival_date )
                ,NULL
                ,xmrih.ship_to_locat_id
                ,NVL( xmrih.actual_career_id,xmrih.career_id )
                ,NVL( xmrih.actual_shipping_method_code,xmrih.shipping_method_code )
                ,gc_sp_class_move
                ,xmrih.delivery_no
                ,xmrih.mov_num
                ,xmril.mov_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xmril.instruct_qty,0)
                ,NVL(xmril.ship_to_quantity, 0)
                ,NVL(xmril.shipped_quantity,0)
                ,xmrih.status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xmrih.freight_charge_class
                ,mcb1.segment1
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n)
      ) trn
    ;
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 �{�ԏ�Q#333 Add End
    ---------------------------------------------------------------------------------------------------------------------
--
    -- �ۗ��f�[�^�擾
    CURSOR cu_reserv
    IS
      SELECT xil.segment1                     AS location_code    -- �o�ɑq�ɃR�[�h
            --,xil.description                  AS location_name    -- �o�ɑq�ɖ��� 2008/10/10 �����e�X�g��Q#338 Del
            ,SUBSTRB(xil.description,1,20)    AS location_name    -- �o�ɑq�ɖ���   2008/10/10 �����e�X�g��Q#338 Add
            ,xshi.shipped_date                AS ship_date        -- �o�ɓ�
            ,xshi.arrival_date                AS arvl_date        -- ���ɓ�
-- mod start ver1.1
--            ,NULL                             AS po_no            -- ���������F�Ǌ����_
            ,NULL                             AS head_sales_branch -- ���������F�Ǌ����_
-- mod end ver1.1
            -- 2008/12/06 Modify T.Miyata Start #516 �˗�No�ɕR�t�����ɐ悪����Ε\������B
            , xilv.inventory_location_id        AS deliver_id
            -- 2008/12/06 Modify T.Miyata End #516
            ,xshi.freight_carrier_code        AS career_id        -- ���������F�^���Ǝ�
            ,xshi.shipping_method_code        AS ship_method_code -- ���������F�z���敪
            ,xshi.eos_data_type               AS order_type       -- �Ɩ���ʁi�R�[�h�j
            ,xshi.delivery_no                 AS delivery_no      -- �z���m��
            ,xshi.order_source_ref            AS request_no       -- �˗��m��
            ,xsli.line_id                     AS order_line_id    -- ���������F���ׂh�c
            ,ximv.item_id                     AS item_id          -- ���������F�i�ڂh�c
            ,ximv.item_no                     AS item_code        -- �i�ڃR�[�h
            ,ximv.item_short_name             AS item_name        -- �i�ږ���
            ,ximv.lot_ctl                     AS lot_ctl          -- ���������F���b�g�g�p
            ,xsli.orderd_quantity             AS quant_r          -- �˗���
            ,xsli.ship_to_quantity            AS quant_i          -- ���ɐ�
            ,xsli.shiped_quantity             AS quant_o          -- �o�ɐ�
-- 2008/07/24 A.Shiina v1.7 ADD Start
            ,xsli.detailed_quantity           AS quant_d          -- ���󐔗�(�C���^�t�F�[�X�p)
-- 2008/07/24 A.Shiina v1.7 ADD End
            ,NULL                             AS status           -- �w�b�_�X�e�[�^�X
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xshi.filler14                    AS freight_charge_code   -- �^���敪
            --,xcv.complusion_output_code       AS complusion_output_kbn -- �����o�͋敪  -- 2008/10/31 �����w�E#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- �����o�͋敪 -- 2008/10/31 �����w�E#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
      FROM xxwsh_shipping_headers_if  xshi      -- �o�׈˗��C���^�t�F�[�X�w�b�_�A�h�I��
          ,xxwsh_shipping_lines_if    xsli      -- �o�׈˗��C���^�t�F�[�X���׃A�h�I��
          ,xxcmn_item_locations2_v    xil       -- �n�o�l�ۊǏꏊ�}�X�^
          ,xxcmn_item_mst2_v          ximv      -- �n�o�l�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v   xicv      -- �n�o�l�i�ڃJ�e�S���������VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- �^���Ǝҏ��VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
          -- 2008/12/06 Modify T.Miyata Start #516 �˗�No�ɕR�t�����ɐ悪����Ε\������B
          ,xxcmn_item_locations_v        xilv
          -- 2008/12/06 Modify T.Miyata End #516
      WHERE
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�i��
      ----------------------------------------------------------------------------------------------
      -- �p�����[�^�����D���i�敪
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- �p�����[�^�����D�i�ڋ敪
      AND   xicv.item_class_code    = NVL( gr_param.item_div, xicv.prod_class_code )
      AND   ximv.item_id                = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xsli.orderd_item_code       = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- �h�e����
      ----------------------------------------------------------------------------------------------
      AND   xsli.reserved_status  = gc_reserved_status_y        -- �ۗ��X�e�[�^�X = �ۗ�
      AND   xshi.header_id        = xsli.header_id
      ----------------------------------------------------------------------------------------------
      -- �n�o�l�ۊǏꏊ
      ----------------------------------------------------------------------------------------------
-- del start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- �p�����[�^�����D�u���b�N�P�E�Q�E�R
-- 2008/07/24 A.Shiina v1.7 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R���S��NULL�̏ꍇ
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- �p�����[�^�����D�u���b�N�P�E�Q�E�R�̉��ꂩ���w�肳�ꂽ�ꍇ
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- �p�����[�^�����D�I�����C���敪
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xshi.location_code    = xil.segment1
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- �h�e�w�b�_
      ----------------------------------------------------------------------------------------------
      AND   xshi.eos_data_type  IN( gc_eos_type_rpt_move_o      -- �ړ��o�Ɋm���
                                   ,gc_eos_type_rpt_move_i )    -- �ړ����Ɋm���
      -- �p�����[�^�����D�˗��m��
      AND   xshi.order_source_ref = NVL( gr_param.request_no, xshi.order_source_ref )
-- add start ver1.1
      -- �p�����[�^�����D�o�Ɍ�
      AND xshi.location_code    = NVL( gr_param.deliver_from, xshi.location_code )
      -- �p�����[�^�����D�w������
      AND xshi.report_post_code = NVL( gr_param.dept_code, xshi.report_post_code )
-- add end ver1.1
      -- �p�����[�^�����D�o�ɓ�FromTo
      AND   xshi.shipped_date     BETWEEN gr_param.date_from
                                  AND     NVL( gr_param.date_to, xshi.shipped_date )
--
      -- 2008/10/31 �����w�E#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xshi.freight_carrier_code         =   xcv.party_number
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xshi.shipped_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xshi.shipped_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 �����w�E#461 Del End ---------------------------------------
--
      -- 2008/10/31 �����w�E#461 Add Start -------------------------------------
      AND   NVL(xshi.freight_carrier_code,gv_nvl_null_char) =   xcv.party_number(+)
      AND   xshi.shipped_date            >=   xcv.start_date_active(+)
      AND   xshi.shipped_date            <=   xcv.end_date_active(+)
      -- 2008/10/31 �����w�E#461 Add End ---------------------------------------
      -- 2008/12/06 Modify T.Miyata Start #516 �˗�No�ɕR�t�����ɐ悪����Ε\������B
      AND   xshi.ship_to_location  = xilv.segment1(+)
      -- 2008/12/06 Modify T.Miyata End #516
--
    ;
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �w�����уf�[�^���o�E�o�^����
    -- ====================================================
    -- �o�͋敪���u�ۗ��v�ȊO�̏ꍇ
    IF (  ( gr_param.output_type IS NULL )
       OR ( gr_param.output_type <> gc_output_type_rsrv ) ) THEN
      <<main_loop>>
      FOR re_main IN cu_main LOOP
        --------------------------------------------------
        -- ���o�f�[�^�i�[
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- �o�ɑq�ɃR�[�h
        lr_get_data.location_name    := re_main.location_name ;     -- �o�ɑq�ɖ���
        lr_get_data.ship_date        := re_main.ship_date ;         -- �o�ɓ�
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- ���ɓ�
-- mod start ver1.1
--        lr_get_data.po_no            := re_main.po_no ;             -- ���������F�Ǌ����_
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- ���������F�Ǌ����_
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- ���������F�z����
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- �^���敪
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- �����o�͋敪
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- ���������F�^���Ǝ�
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- ���������F�z���敪
        lr_get_data.order_type       := re_main.order_type ;        -- �Ɩ���ʁi�R�[�h�j
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- �z���m��
        lr_get_data.request_no       := re_main.request_no ;        -- �˗��m��
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- ���������F���ׂh�c
        lr_get_data.item_id          := re_main.item_id ;           -- ���������F�i�ڂh�c
        lr_get_data.item_code        := re_main.item_code ;         -- �i�ڃR�[�h
        lr_get_data.item_name        := re_main.item_name ;         -- �i�ږ���
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- ���������F���b�g�g�p
        lr_get_data.quant_r          := re_main.quant_r ;           -- �˗����i���b�g�Ǘ��O�j
        lr_get_data.quant_i          := re_main.quant_i ;           -- ���ɐ��i���b�g�Ǘ��O�j
        lr_get_data.quant_o          := re_main.quant_o ;           -- �o�ɐ��i���b�g�Ǘ��O�j
        lr_get_data.status           := re_main.status ;            -- �󒍃w�b�_�X�e�[�^�X
-- add start ver1.1
        lr_get_data.conv_unit        := re_main.conv_unit ;         -- ���o�Ɋ��Z�P��
        lr_get_data.num_of_cases     := re_main.num_of_cases ;      -- �P�[�X����
-- add end ver1.1
-- add start ver1.2
        lr_get_data.lot_id           := re_main.lot_id ;            -- ���b�gID
-- add end ver1.2
-- add start ver1.3
        lr_get_data.prod_class_code  := re_main.prod_class_code ;   -- ���i�敪
-- add end ver1.3
-- 2008/11/17 �����w�E#651 Add Start ---------------------------------------
        lr_get_data.no_instr_actual  := re_main.no_instr_actual ;
        lr_get_data.lot_inst_cnt     := re_main.lot_inst_cnt ;
        lr_get_data.row_num          := re_main.row_num ;
-- 2008/11/17 �����w�E#651 Add End -----------------------------------------
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^�f�[�^�ݒ�
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
    END IF ;
--
    -- ====================================================
    -- �ۗ��f�[�^���o�E�o�^����
    -- ====================================================
    -- �o�͋敪���u�ۗ��v�̏ꍇ
    IF (  ( gr_param.output_type IS NULL )
       OR ( gr_param.output_type = gc_output_type_rsrv ) ) THEN
      <<reserv_loop>>
      FOR re_main IN cu_reserv LOOP
        --------------------------------------------------
        -- ���o�f�[�^�i�[
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- �o�ɑq�ɃR�[�h
        lr_get_data.location_name    := re_main.location_name ;     -- �o�ɑq�ɖ���
        lr_get_data.ship_date        := re_main.ship_date ;         -- �o�ɓ�
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- ���ɓ�
-- mod start ver1.1
--        lr_get_data.po_no            := re_main.po_no ;             -- ���������F�Ǌ����_
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- ���������F�Ǌ����_
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- ���������F�z����
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- �^���敪
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- �����o�͋敪
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- ���������F�^���Ǝ�
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- ���������F�z���敪
        lr_get_data.order_type       := re_main.order_type ;        -- �Ɩ���ʁi�R�[�h�j
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- �z���m��
        lr_get_data.request_no       := re_main.request_no ;        -- �˗��m��
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- ���������F���ׂh�c
        lr_get_data.item_id          := re_main.item_id ;           -- ���������F�i�ڂh�c
        lr_get_data.item_code        := re_main.item_code ;         -- �i�ڃR�[�h
        lr_get_data.item_name        := re_main.item_name ;         -- �i�ږ���
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- ���������F���b�g�g�p
        lr_get_data.quant_r          := re_main.quant_r ;           -- �˗����i���b�g�Ǘ��O�j
        lr_get_data.quant_i          := re_main.quant_i ;           -- ���ɐ��i���b�g�Ǘ��O�j
        lr_get_data.quant_o          := re_main.quant_o ;           -- �o�ɐ��i���b�g�Ǘ��O�j
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
        lr_get_data.quant_d          := re_main.quant_d  ;          -- ���󐔗�(�C���^�t�F�[�X�p)
-- 2008/07/24 A.Shiina v1.7 UPDATE End
        lr_get_data.status           := re_main.status ;            -- �w�b�_�X�e�[�^�X
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^�f�[�^�ݒ�
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- ���ԃe�[�u���o�^
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
    END IF ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
-- add start ver1.1
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
-- add end   ver1.1
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
  END prc_create_move_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�ҏW
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
-- add start ver1.1
    -- ====================================================
    -- ���ԃe�[�u��������
    -- ====================================================
    DELETE FROM xxwsh_930c_tmp;
-- add end ver1.1
    -- ====================================================
    -- �o�ׁE�x���f�[�^���o����
    -- ====================================================
    -- �Ɩ���ʂ��u�o�ׁv�E�u�x���v�̏ꍇ
    IF (  ( gr_param.business_type IS NULL )
       OR ( gr_param.business_type = gc_business_type_s ) 
       OR ( gr_param.business_type = gc_business_type_p ) ) THEN
      prc_create_ship_data
        (
          ov_errbuf     => lv_errbuf 
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg 
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �ړ��f�[�^���o����
    -- ====================================================
    -- �Ɩ���ʂ��u�ړ��v�̏ꍇ
    IF (  ( gr_param.business_type IS NULL )
       OR ( gr_param.business_type = gc_business_type_m ) ) THEN
      prc_create_move_data
        (
          ov_errbuf     => lv_errbuf 
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg 
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- �w�l�k�f�[�^�o�͏���
    -- ====================================================
    prc_create_out_data
      (
        ov_errbuf     => lv_errbuf 
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg 
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
-- add start ver1.1
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
-- add end   ver1.1
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_business_type      IN     VARCHAR2         -- 01 : �Ɩ����
     ,iv_prod_div           IN     VARCHAR2         -- 02 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 03 : �i�ڋ敪
     ,iv_date_from          IN     VARCHAR2         -- 04 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 05 : �o�ɓ�To
     ,iv_dept_code          IN     VARCHAR2         -- 06 : ����
     ,iv_output_type        IN     VARCHAR2         -- 07 : �o�͋敪
     ,iv_deliver_type       IN     VARCHAR2         -- 08 : �o�Ɍ`��
     ,iv_block_01           IN     VARCHAR2         -- 09 : �u���b�N�P
     ,iv_block_02           IN     VARCHAR2         -- 10 : �u���b�N�Q
     ,iv_block_03           IN     VARCHAR2         -- 11 : �u���b�N�R
     ,iv_deliver_from       IN     VARCHAR2         -- 12 : �o�Ɍ�
     ,iv_online_type        IN     VARCHAR2         -- 13 : �I�����C���Ώۋ敪
     ,iv_request_no         IN     VARCHAR2         -- 14 : �˗�No�^�ړ�No
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.business_type    := iv_business_type ;                           -- �Ɩ����
    gr_param.prod_div         := iv_prod_div ;                                -- ���i�敪
    gr_param.item_div         := iv_item_div ;                                -- �i�ڋ敪
    gr_param.date_from        := FND_DATE.CANONICAL_TO_DATE( iv_date_from ) ; -- �o�ɓ�From
    gr_param.date_to          := FND_DATE.CANONICAL_TO_DATE( iv_date_to   ) ; -- �o�ɓ�To
    gr_param.dept_code        := iv_dept_code ;                               -- ����
    gr_param.output_type      := iv_output_type ;                             -- �o�͋敪
    gr_param.deliver_type_id  := iv_deliver_type ;                            -- �o�Ɍ`��
    gr_param.block_01         := iv_block_01 ;                                -- �u���b�N�P
    gr_param.block_02         := iv_block_02 ;                                -- �u���b�N�Q
    gr_param.block_03         := iv_block_03 ;                                -- �u���b�N�R
    gr_param.deliver_from     := iv_deliver_from ;                            -- �o�Ɍ�
    gr_param.online_type      := iv_online_type ;                             -- �I�����C���Ώۋ敪
    gr_param.request_no       := iv_request_no ;                              -- �˗�No�^�ړ�No
    -- -----------------------------------------------------
    -- ���O�C�����ޔ��i�v�g�n�J�����p�j
    -- -----------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- �쐬��
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- �b�o�E�A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- �R���J�����g�E�v���O����ID
--
    -- =====================================================
    -- ���O�C�����[�U�[���o��
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �w�l�k�t�@�C���f�[�^�ҏW
    -- =====================================================
    -- --------------------------------------------------
    -- ���X�g�O���[�v�J�n�^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- �w�l�k�f�[�^�ҏW�������Ăяo���B
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- ���X�g�O���[�v�I���^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- ���[�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- �O�����b�Z�[�W�̎擾
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_lctn_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_lctn>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_lctn>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_lctn_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- �w�l�k�o��
      -- --------------------------------------------------
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
    -- ==================================================
    -- ���ԃe�[�u�����[���o�b�N
    -- ==================================================
    ROLLBACK ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_business_type      IN     VARCHAR2         -- 01 : �Ɩ����
     ,iv_prod_div           IN     VARCHAR2         -- 02 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 03 : �i�ڋ敪
     ,iv_date_from          IN     VARCHAR2         -- 04 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 05 : �o�ɓ�To
     ,iv_dept_code          IN     VARCHAR2         -- 06 : ����
     ,iv_output_type        IN     VARCHAR2         -- 07 : �o�͋敪
     ,iv_deliver_type       IN     VARCHAR2         -- 08 : �o�Ɍ`��
     ,iv_block_01           IN     VARCHAR2         -- 09 : �u���b�N�P
     ,iv_block_02           IN     VARCHAR2         -- 10 : �u���b�N�Q
     ,iv_block_03           IN     VARCHAR2         -- 11 : �u���b�N�R
     ,iv_deliver_from       IN     VARCHAR2         -- 12 : �o�Ɍ�
     ,iv_online_type        IN     VARCHAR2         -- 13 : �I�����C���Ώۋ敪
     ,iv_request_no         IN     VARCHAR2         -- 14 : �˗�No�^�ړ�No
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcmn820004c.main' ;  -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain
      (
        iv_business_type  => iv_business_type                     -- 01 : �Ɩ����
       ,iv_prod_div       => iv_prod_div                          -- 02 : ���i�敪
       ,iv_item_div       => iv_item_div                          -- 03 : �i�ڋ敪
       ,iv_date_from      => iv_date_from                         -- 04 : �o�ɓ�From
       ,iv_date_to        => NVL( iv_date_to, gc_max_date_char )  -- 05 : �o�ɓ�To
       ,iv_dept_code      => iv_dept_code                         -- 06 : ����
       ,iv_output_type    => iv_output_type                       -- 07 : �o�͋敪
       ,iv_deliver_type   => iv_deliver_type                      -- 08 : �o�Ɍ`��
       ,iv_block_01       => iv_block_01                          -- 09 : �u���b�N�P
       ,iv_block_02       => iv_block_02                          -- 10 : �u���b�N�Q
       ,iv_block_03       => iv_block_03                          -- 11 : �u���b�N�R
       ,iv_deliver_from   => iv_deliver_from                      -- 12 : �o�Ɍ�
       ,iv_online_type    => iv_online_type                       -- 13 : �I�����C���Ώۋ敪
       ,iv_request_no     => iv_request_no                        -- 14 : �˗�No�^�ړ�No
       ,ov_errbuf         => lv_errbuf                            -- �G���[�E���b�Z�[�W
       ,ov_retcode        => lv_retcode                           -- ���^�[���E�R�[�h
       ,ov_errmsg         => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh930003c ;
/
